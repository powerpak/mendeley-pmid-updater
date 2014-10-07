require "open-uri"
require "json"
require "uri"
require "nokogiri"
require "andand"

class PMCIDConverter
  
  PMC_API_URL = 'http://www.pubmedcentral.nih.gov/utils/idconv/v1.0/?format=json'
  PUBMED_URL = 'http://www.ncbi.nlm.nih.gov/pubmed/?report=xml&format=text'
  EUTILS_SEARCH = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&usehistory=n'
  EUTILS_FETCH = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml'
  EUTILS_INTERVAL = 1.0/3.0
  EUTILS_TOOL = ['tool', 'mendeley-pmid-updater']
  EUTILS_EMAIL = ['email', 'theodore.r.pak@gmail.com']
  
  @@last_access = nil
  
  class << self
    
    def convert(id, id_type)
      begin
        pmc_api_convert id
      rescue PMCIDConverterError => e
        begin
          pubmed_search id, id_type
        rescue PMCIDConverterError => e
          
        end
      end
    end
    
    def pmc_api_convert(id)
      uri = URI(PMC_API_URL)
      ar = URI.decode_www_form(uri.query) << ["ids", id]
      uri.query = URI.encode_www_form(ar)
      begin
        open(uri) do |json|
          response = JSON.parse json.read
          unless response["status"] == "ok"
            raise PMCIDConverterError.new("PMC ID Converter API returned an error: #{response['message']}", response)
          end
          unless response["records"].length > 0
            raise PMCIDConverterError.new("PMC ID Converter API returned no results", response)
          end
          first_result = response["records"].first
          if first_result["status"] == "error"
            raise PMCIDConverterError.new("PMC ID Converter API could not find this ID: #{id}", response)
          end
          {
            :pmcid => first_result["pmcid"],
            :pmid => first_result["pmid"],
            :doi => first_result["doi"]
          }
        end
      rescue OpenURI::HTTPError => ex
        raise PMCIDConverterError.new("PMC ID Converter API could not open #{uri}", nil)
      end
    end
    
    def pubmed_search(id, id_type)
      fields = {:doi => "DOI", :pmid => "uid"}
      term = "#{id}[#{fields[id_type]}]"
      
      uri = URI(EUTILS_SEARCH)
      ar = URI.decode_www_form(uri.query) << ["term", term] << EUTILS_TOOL << EUTILS_EMAIL
      uri.query = URI.encode_www_form(ar)
      
      ncbi_access_wait
      open(uri) do |xml|
        nk = Nokogiri::XML.parse(xml)
        nk_id = nk.css("Id").first
        unless nk_id
          raise PMCIDConverterError.new("Eutils could not find results for #{id_type}: #{id}", nk)
        end
        
        uri = URI(EUTILS_FETCH)
        ar = URI.decode_www_form(uri.query) << ["id", nk_id.text] << EUTILS_TOOL << EUTILS_EMAIL
        uri.query = URI.encode_www_form(ar)
        
        ncbi_access_wait
        open(uri) do |xml|
          nk = Nokogiri::XML.parse(xml)
          {
            :pmcid => nk.css("ArticleId[IdType=pmc]").first.andand.text,
            :pmid => nk.css("PMID").first.andand.text,
            :doi => nk.css("ArticleId[IdType=doi]").first.andand.text
          }
        end
      end
    end
    
    # Limit access to EUtils to no more than three requests a second
    # as required here: http://www.ncbi.nlm.nih.gov/books/NBK25497/
    # I can find no such documented limit for the PMC ID Converter API.
    def ncbi_access_wait(wait = EUTILS_INTERVAL)
      @@last_access_mutex ||= Mutex.new
      @@last_access_mutex.synchronize {
        if @@last_access
          duration = Time.now - @@last_access
          if wait > duration
            sleep wait - duration
          end
        end
        @@last_access = Time.now
      }
      nil
    end
    
  end
  
end

class PMCIDConverterError < RuntimeError
  attr_reader :response
  attr_reader :message
  
  def initialize(message, response)
    @message = message
    @response = response
  end
  
  def to_s; @message; end
end
