require "csv"
require "trollop"

# Trollop Command-line parameters
opts = Trollop::options do
  version "First OWNERShip script"
  banner <<-EOS

The first ownership script takes in a text file of commit hashes (separated by new lines) for commits that have modified any OWNERS file. 

Produces a CSV including developer email, directory of OWNERS file, and commit hash for when the developer was first added to the OWNERS file.

Usage: 
  ruby #{File.basename(__FILE__)} [options]

where [options] are:
  EOS
  opt :commitHashes, "The file name including path of the file containing the commit hashes to use",  :required => true , type: String
  opt :src, "The directory of the Chromium source code",  :required => true, type: String
  opt :csv, "The output CSV file for the results", default: "../first-owners.csv", type: String
end 


#
# A scraper to find the time a person was initially added as an OWNER
# 
# @author Danielle Neuberger
# @author Richard Kalimba
class FirstOwnershipScript

  # Create a new instance
  # @return FirstOwnershipScript instance - the new object
  def initialize(opts)
    File.open(opts[:csv], 'w+').close
    @commitNumsFile = File.expand_path(opts[:commitHashes])
    @csvLoc = File.expand_path(opts[:csv])
	@srcLoc = File.expand_path(opts[:src])
    @hashmap = Hash.new(0)
  end

  def run_script()
	get_ownership()
  end
  # Method to loop through commit nums in the passed file and call helper methods
  # to pull information for each 
  def get_ownership()    
    File.readlines(@commitNumsFile).each do |line|
      analyze_commit_file(line) #assumes each line has only the commit hash
    end
    create_csv()
  end

  # Checks out the commit and opens the file, gathers all the
  # owners emails and puts the information along with the commit hash
  # , path, and date into the owner-ownerfile hash
  def analyze_commit_file(commitNum)
    
	Dir.chdir @srcLoc do
	  filesWithPaths = `git diff-tree --no-commit-id --name-only -r #{commitNum}`.split(/\n/)
      date = `git show -s --format=%ci #{commitNum}`
      filesWithPaths.each do |file|
        if file.include? "OWNERS"  #if the file is an owners file
	      path = File.dirname(file) + "/" #format path to just be the directory (eg /chrome/common/OWNERS -> /chrome/common/)
          commitNum = commitNum.strip()
          get_owner_email(file, commitNum, date, path)
        end
      end
	end
  end

  # Open up an owners file and add information to the hash
  def get_owner_email(file, commitNum, date, path)
    ownersText = `git show #{commitNum}:#{file}`
    ownersText.each_line do |line|
      case line
		when /^[^=][a-z0-9_-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
          line.slice!(-1)
          email = line
		when /^\*$/	#i.e. the entire line is just *
          email = "ALL"
		when /per-file.+=.*\*/
          email = "ALL"
		when /per-file.+@.+/
          line.slice!(-1)
          email = line.split('=')[-1]
	  end
	  add_first_ownership(email, path, commitNum, date) unless email.nil?
    end
  end
  
  def add_first_ownership(email, path, commitNum, date)
      key = email + "~" + path
      value = [commitNum, date]
      
	  if @hashmap.key?(key)
  	    currHashDate = @hashmap[key][0]
        if date < currHashDate
          @hashmap[key] = value
        end
      else 
	    @hashmap[key] = value
      end
  end

  # Add information to the CSV file in format of 
  #  email, directory, commit id
  def create_csv()
    CSV.open(@csvLoc, "a") do |cfile|
      @hashmap.each do |key, val|
	emailAndDir = key.split(/~/)
        cfile << [emailAndDir[0],emailAndDir[1],val[0]]
      end
    end
  end
end


#driver code
f = FirstOwnershipScript.new(opts)
f.run_script()
puts "Done."