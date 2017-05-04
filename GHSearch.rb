require 'octokit'
require_relative "WriteResult"

class GHSearch

	def initialize(login, password, language, numberForks, numberStars)
		@login = login
		@password = password
		@language = language
		@numberForks = numberForks
		@numberStars = numberStars
		@writeResult = WriteResult.new()
	end

	def runSearch()

		client = runAuthentication()
		queryGeneral = "language:#{@language} forks:\">=#{@numberForks}\" stars:\">=#{@numberStars}\""
		results = client.search_repositories(queryGeneral)
		total_count = results.total_count

		last_response = client.last_response
		number_of_pages = last_response.rels[:last].href.match(/page=(\d+).*$/)[1]

		puts "There are #{total_count} results, on #{number_of_pages} pages!"
		puts "And here's the first path for every set"
		puts last_response.data.items.first.path
		
		until last_response.rels[:next].nil?
			last_response = last_response.rels[:next].get
			sleep 4 # back off from the API rate limiting; don't do this in Real Life
			break if last_response.rels[:next].nil?
			last_response.data.items.each do |project|
			  	name = project["full_name"]
			  	queryTravis = "in:path repo:#{name} filename:.travis.yml"
			  	projectTravis = client.search_code(queryTravis)
			  	if (projectTravis.total_count > 0)
					queryConfig = "in:path repo:#{name} filename:pom.xml"
			  		projectConfig = client.search_code(queryConfig)
					if (projectConfig.total_count > 0)
						queryGradle = "in:path repo:#{name} filename:build.gradle"
			  			projectGradle = client.search_code(queryGradle)
						if (projectGradle.total_count <= 0)
							print name
							print "\n"
							@writeResult.writeNewProject(name)
							@writeResult.writeProjectMetrics(name, project["forks_count"], project["stargazers_count"], project["size"])
							sleep 4
						end
					end
				end
				sleep 10
			end
		end
		writeResult.closeProjectListFile()
	end

	def runAuthentication()
		return Octokit::Client.new \
	  		:login    => @login,
	  		:password => @password
	end

end