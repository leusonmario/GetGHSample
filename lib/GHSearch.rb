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

		client = runAuthentication()
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
		@writeResult.closeProjectListFile()
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
