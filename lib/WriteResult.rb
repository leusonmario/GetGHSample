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
		@projectList.puts("\"#{projectName}\"")
	end

	def closeProjectListFile()
		@projectList.close
	end

	def createCSVResult()
		CSV.open("ProjectMetrics.csv", "ab") do |csv|
			csv << ["ProjectName", "NumberForks", "NumberStars", "Size"]
		end
	end

	def writeProjectMetrics(projectName, numberForks, numberStars, size)
		CSV.open("ProjectMetrics.csv", "ab") do |csv|
			csv << [projectName, numberForks, numberStars, size]
		end
	end

end