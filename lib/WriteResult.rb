require 'fileutils'
require 'csv'
require 'rubygems'

class WriteResult

	def initialize()
		@projectList = createProjectList()
		createCSVResult()
	end

	def createProjectList()
		return File.new("projectList.txt", "a+")
	end

	def writeNewProject(projectName)
		@projectList.puts("https://github.com/#{projectName},#{projectName.split("/").last}")
	end

	def closeProjectListFile()
		@projectList.close
	end

	def createCSVResult()
		CSV.open("ProjectMetrics.csv", "ab") do |csv|
			csv << ["ProjectName", "NumberForks", "NumberStars", "Size", "NumberIssues", "NumberAuthors", "NumberCommits", 
				"NumberCommitsLastMonth", "NumberCommitsLast6Months", "NumberCommitsLastYear", "TravisAdoption"]
		end
	end

	def writeProjectMetrics(projectName, numberForks, numberStars, size, numberIssues, authors, numberCommits, numberCommitsLastMonth,
		numberCommitsLast6Months, numberCommitsLastYear, travisAdoption)
		CSV.open("ProjectMetrics.csv", "ab") do |csv|
			csv << [projectName, numberForks, numberStars, size, numberIssues, authors, numberCommits, numberCommitsLastMonth,
				numberCommitsLast6Months, numberCommitsLastYear, travisAdoption]
		end
	end

end