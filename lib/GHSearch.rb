require 'octokit'
require 'travis'
require_relative "WriteResult"

class GHSearch

	def initialize(login, password, language, numberForks, numberStars, dataFilter)
		@login = login
		@password = password
		@language = language
		@numberForks = numberForks
		@numberStars = numberStars
		@dataFilter = dataFilter
		@writeResult = WriteResult.new()
	end

	def runSearch()

		csv_text = File.read(Dir.pwd+'/sample.csv')

		indexLine = 0
		CSV.parse(csv_text, :headers => true).each do |row|
			client = runAuthentication()
			repo = client.repo row[0]
			metrics = cloneProjectLocally(row[0], row[0].to_s.split("/").last)
			if (indexLine == 2)
				break
			end
			indexLine += 1
			@writeResult.writeProjectMetrics(row[0].to_s, repo["forks_count"].to_s.to_i, repo["stargazers_count"].to_s.to_i, repo["size"].to_s.to_i, 
				repo["open_issues_count"].to_s.to_i, metrics[4].to_s.to_i, metrics[0].to_s.to_i, metrics[1].to_s.to_i, metrics[2].to_s.to_i, 
				metrics[3].to_s.to_i, metrics[5].to_s.to_i)
		end
		@writeResult.closeProjectListFile()
	end

	def cloneProjectLocally(projectName, nameFolder)
		currentPath = Dir.pwd
		clone = %x(git clone https://github.com/#{projectName} #{nameFolder})
		Dir.chdir nameFolder
		
		numberCommits = 0
		numberCommitsLastMonth = 0
		numberCommitsLast6Months = 0
		numberCommitsLastYear = 0
		numberAuthors = 0
		tempoTravis = 0
		
		begin
			numberCommits = %x(git rev-list --count HEAD)
			numberCommitsLastMonth = %x(git rev-list HEAD --count --since=17/07/2021)
			numberCommitsLast6Months = %x(git rev-list HEAD --count --since=17/02/2021)
			numberCommitsLastYear = %x(git rev-list master --count --since=17/08/2020)
			numberAuthors = %x(git log --format="%an" | sort -u).split("\n").size()
			tempoTravis = %x(git log --diff-filter=A --pretty=format:'%C(auto)%h%d (%cr) %cn <%ce> %s'  -- .travis.yml).to_s.scan(/([0-9]+ (year(s)* ago))/).last.first.to_s.scan(/[0-9]*/).first		
		rescue => exception
			print(exception)
		end
		deleteProject(nameFolder, currentPath)

		Dir.chdir currentPath
		return numberCommits, numberCommitsLastMonth, numberCommitsLast6Months, numberCommitsLastYear, numberAuthors, tempoTravis
	end

	def deleteProject(nameFolder, currentPath)
		Dir.chdir currentPath
		%x(rm -rf #{nameFolder})
	end

	def isProjectActive(projectName)
		begin
			repository = Travis::Repository.find(projectName)
			return (repository.active and (Date.parse(repository.last_build_started_at.to_s.scan(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/).first) > Date.parse(@dataFilter.to_s)))
		rescue StandardError => msg  
			puts msg
		end
		return false
	end

	def runAuthentication()
		return Octokit::Client.new \
	  		:login    => @login,
				:password => @password
	end

end
