#!/usr/bin/env ruby

require_relative 'GHSearch'

parameters = []
File.open("properties", "r") do |text|
	indexLine = 0
	text.each_line do |line|
		parameters[indexLine] = line[/\<(.*?)\>/, 1]
		indexLine += 1
	end
end

search = GHSearch.new(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4])
search.runSearch()