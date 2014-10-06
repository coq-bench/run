require 'erb'
require 'fileutils'
require_relative 'backup'

include(ERB::Util)

backup = Backup.new("csv")

# Generate the index
renderer = ERB.new(File.read("index.html.erb"))
File.open("index.html", "w") do |file|
  file << renderer.result()
end
puts "index.html"

# Generate the history
for name, versions in backup.packages do
  folder = File.join("history", name)
  FileUtils.mkdir_p(folder)
  for version in versions do
    renderer = ERB.new(File.read("history.html.erb"))
    file_name = File.join(folder, "#{version}.html")
    File.open(file_name, "w") do |file|
      file << renderer.result()
    end
    puts file_name
  end
end