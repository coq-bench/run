# Generate an HTML website from the CSV backup
require 'erb'
require 'fileutils'
require_relative 'backup'

FileUtils.mkdir_p("html")

# Copy the CSS and JavaScript
FileUtils.cp(["bootstrap.min.css", "bootstrap.min.js"], "html/")

# Prepare ERB
include(ERB::Util)
backup = Backup.new("csv")

# Generate the index
renderer = ERB.new(File.read("index.html.erb", :encoding => "UTF-8"))
File.open("html/index.html", "w") do |file|
  file << renderer.result().gsub(/\n\s*\n/, "\n")
end
puts "index.html"

# Generate the history
for name, versions in backup.packages do
  FileUtils.mkdir_p("html/history/#{name}")
  for version in versions do
    renderer = ERB.new(File.read("history.html.erb", :encoding => "UTF-8"))
    file_name = "html/history/#{name}/#{version}.html"
    File.open(file_name, "w") do |file|
      file << renderer.result().gsub(/\n\s*\n/, "\n")
    end
    puts file_name
  end
end