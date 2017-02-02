require_relative "lib/mendeley-database"

task :default => :dry_run

desc "Ensures Mendeley is shut down before messing with the database"
task :shutdown_mendeley do |t|
  if `ps aux | grep -i mendeley | grep -v grep` != ''
    fail "Please close Mendeley before running this script."
  end
end

desc "Backs up the Mendeley database in case everything goes to hell"
task :backup => :shutdown_mendeley do |t|
  backup_location = MendeleyDatabase.backup
  puts "Current database backed up to #{backup_location}"
end

desc "Scans your Mendeley database to see what IDs can be retrieved."
task :dry_run => :backup do |t, args|
  md = MendeleyDatabase.new
  md.dry_run
end

desc "Updates author names"
# The `quietly` param will suppress progress messages.
task :fix_authors, [:quietly] => :backup do |t, args|
  md = MendeleyDatabase.new
  md.verbose = false if !args.quietly.nil?
  md.fix_author_names
end

desc "Fills in missing PMIDs, PMCIDs, and DOIs in the Mendeley database."
# The `quietly` param will suppress progress messages.
# The `overwrite_fields` will allow the script to update non-empty fields (by default it only touches empty fields.)
task :update_ids, [:quietly, :overwrite_fields] => :backup do |t, args|
  md = MendeleyDatabase.new
  md.verbose = false if !args.quietly.nil?
  md.update_nils_only = false if !args.update_all.nil?
  md.fix!
end