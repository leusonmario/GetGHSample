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

		# number of commits - (ok)
		# years from the first adoption of Travis CI - local (ok)
		# number of forks - (ok)
		# commits activity measured in terms of number of commits in the last month or other measures - local (ok)
		# size - (ok)
		# number of developers - github - authors (ok)

		client = runAuthentication()
		repo = client.repo 'arouel/uadetector'
		#Octokit.commits(repo)
		#commits = client.repo 'randoop/randoop'
		print("Number of forks : " + repo["forks_count"].to_s)
		print("\n")
		print("Number of stars : " + repo["stargazers_count"].to_s)
		print("\n")
		print("Size : " + repo["size"].to_s)
		print("\n")
		print("Number of issues : " + repo["open_issues_count"].to_s)
		print("\n")
		cloneProjectLocally("arouel/uadetector", "uadetector")

=begin
		queryGeneral = "language:#{@language} forks:\">#{@numberForks}\" stars:\">#{@numberStars}\""
		results = client.search_repositories(queryGeneral,:per_page => 100)
		total_count = results.total_count
		
		last_response = client.last_response
		number_of_pages = last_response.rels[:last].href.match(/page=(\d+).*$/)[1]

		puts "There are #{total_count} results, on #{number_of_pages} pages!"
		puts "And here's the first path for every set"
		puts last_response.data.items.first.path
		
		until last_response.rels[:next].nil?
			last_response = last_response.rels[:next].get
			sleep 5 # back off from the API rate limiting; don't do this in Real Life
			break if last_response.rels[:next].nil?
			last_response.data.items.each do |project|
			  	name = project["full_name"]
			  	queryTravis = "in:path repo:#{name} filename:.travis.yml"
			  	projectTravis = client.search_code(queryTravis)
			  	if (projectTravis.total_count > 0 and isProjectActive(name.to_s))
					queryConfig = "in:path repo:#{name} filename:pom.xml"
			  		projectConfig = client.search_code(queryConfig)
					if (projectConfig.total_count > 0)
						queryGradle = "in:path repo:#{name} filename:build.gradle"
			  			projectGradle = client.search_code(queryGradle)
						if (projectGradle.total_count <= 0)
							print name
							print "\n"
							@writeResult.writeNewProject(name.to_s)
							@writeResult.writeProjectMetrics(name.to_s, project["forks_count"].to_s, project["stargazers_count"].to_s, project["size"].to_s)
						end
					end
				end
				sleep 5
			end
		end
=end
		@writeResult.closeProjectListFile()
	end

	def cloneProjectLocally(projectName, nameFolder)
		Dir.chdir "/home/leusonmario/Documentos/PHD/Research/projects/aux"
		clone = %x(git clone https://github.com/#{projectName} #{nameFolder})
		Dir.chdir nameFolder
		numberCommits = %x(git rev-list --count HEAD)
		numberCommitsLastMonth = %x(git rev-list master --count --since=13/07/2021)
		numberCommitsLast6Months = %x(git rev-list master --count --since=13/02/2021)
		numberCommitsLastYear = %x(git rev-list master --count --since=13/08/2020)
		numberAuthors = %x(git log --format="%an" | sort -u).split("\n").size()
		tempoTravis = %x(git log --diff-filter=A --pretty=format:'%C(auto)%h%d (%cr) %cn <%ce> %s'  -- .travis.yml).to_s.scan(/([0-9]+ (year(s)* ago))/).last.first.to_s.scan(/[0-9]*/).first
		print("Number of commits last month : " + numberCommitsLastMonth)
		print("\n")
		print("Number of commits last 6 months : " + numberCommitsLast6Months)
		print("\n")
		print("Number of commits last year : " + numberCommitsLastYear)
		print("\n")
		print("Number of commit authors : " + numberAuthors.to_s)
		print("\n")
		print("Tempo de Travis : " + tempoTravis.to_s)
		#deleteProject(nameFolder)
	end

	def deleteProject(nameFolder)
		Dir.chdir "/home/leusonmario/Documentos/PHD/Research/projects/aux"
		%x(rm -rf #{@nameFolder})
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
