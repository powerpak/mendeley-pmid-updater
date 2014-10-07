require "sqlite3"
require "os"
require "fileutils"

require_relative "pmc-id-converter"

class MendeleyDatabase
  
  PAPERS_DOI_URL_FORMAT = /^papers2:\/\/[^\/]+\/doi\/(.*)/
  
  class << self
    def location
      if OS.mac?
        glob = 'Library/Application Support/Mendeley Desktop/*@www.mendeley.com.sqlite'
      elsif OS.linux?
        glob = '.local/share/data/Mendeley Ltd./Mendeley Desktop/*@www.mendeley.com.sqlite'
      else
        raise "Unsupported platform - this only runs on Macs or Linux computers, sorry!"
      end
      Dir.glob(File.join(Dir.home, glob)).first or raise "Can't find your Mendeley database"
    end
    
    def backup
      db_path = self.location
      FileUtils.mkdir_p "backups"
      backup_to = "backups/#{Time.now.to_i}-#{File.basename db_path}"
      FileUtils.cp db_path, backup_to
      backup_to
    end
  end
  
  attr_accessor :verbose
  attr_accessor :update_nils_only
  
  ID_COLS = ["doi", "pmid"]
  
  def initialize(db_file=nil)
    db_file ||= self.class.location
    # Opens the database
    @db = SQLite3::Database.new db_file
    @verbose = true
    @update_nils_only = true
  end
  
  def dry_run
    fix_article_ids true
  end

  def fix_article_ids(dry_run=false)
    match_count = 0
    row_count = 0
    
    # For every Document that is a JournalArticle...
    @db.execute("SELECT id, title, year, note, doi, pmid FROM Documents WHERE type='JournalArticle'") do |row|
      id, title, year, note, doi, pmid = row
      urls = []
      row_count += 1
      match = nil
      
      # Get all the URLs for this document
      @db.execute("SELECT url FROM DocumentUrls WHERE documentId=?", [id]) do |url_row|
        urls << url_row.first
      end
      
      # Sometimes we have the DOI as a Papers2 URL instead of it being stored in the doi column.
      # This is an artifact of the importing process.
      papers_doi_urls = urls.select { |url| url =~ PAPERS_DOI_URL_FORMAT }
      if doi.nil? and papers_doi_urls.size > 0
        papers_doi_urls.first =~ PAPERS_DOI_URL_FORMAT
        doi = $1
      end
      
      # In order, we prefer matching by PMID, then DOI
      {:pmid => pmid, :doi => doi}.each do |id_type, id|
        next unless id
        begin
          match = PMCIDConverter.convert(id, id_type)
        rescue PMCIDConverterError => e
          $stderr.puts e.message if @verbose
        end
        break if match
      end
      
      if @verbose
        short_title = "#{title}~"[0..100].gsub(/\s\w+\s*$/, '...').gsub(/~$/, '')
        if match then
          $stderr.puts "Matched \"#{short_title}\""
          match.each do |id_type, id|
            $stderr.puts "  |--> #{id_type.to_s.upcase}: #{id || '?'}"
          end
        else $stderr.puts "Could not match \"#{short_title}\""; end
      end
      
      update_article(id, match) if match && !dry_run
      
      match_count += 1 if match
    end
    
    $stderr.puts "Matched #{match_count} of #{row_count} documents."
  end
  
  def update_article(document_id, match)
    match.each do |id_type, ext_id|
      id_type = id_type.to_s
      now = Time.now.to_i
      next unless ext_id
      if ID_COLS.include? id_type
        if @update_nils_only
          # Don't set things if they are not null
          @db.execute("UPDATE Documents SET #{id_type} = ?, modified = ? WHERE id = ? AND #{id_type} is null",
              [ext_id, now, document_id])
        else
          @db.execute("UPDATE Documents SET #{id_type} = ?, modified = ? WHERE id = ?", [ext_id, now, document_id])
        end
      else
        note = nil
        note_tag = "{:#{id_type.upcase}:#{ext_id}}"
        @db.execute("SELECT note FROM Documents WHERE id = ? LIMIT 1", [document_id]) {|row| note = row.first }
        if note =~ /\{:#{id_type.upcase}:([^}]*)\}/
          # There is already a CSL variable for this id_type in the note field
          note.gsub!(/\{:#{id_type.upcase}:([^}]*)\}/, note_tag) unless @update_nils_only
        elsif note =~ /<m:note>/
          note.gsub!(/<m:note>/, "<m:note>#{note_tag} ")
        elsif note && note.strip.length > 0
          note = "#{note_tag} #{note}"
        else
          note = "<m:note>#{note_tag}</m:note>"
        end
        @db.execute("UPDATE Documents SET note = ? WHERE id = ?", [note, document_id])
      end
    end
  end
  
end