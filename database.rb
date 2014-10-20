# Update the CSV backup of benchmarks
require 'csv'
require 'fileutils'

class Database
  def initialize(folder)
    @folder = folder
  end

  def add_bench(name, version, duration, status)
    FileUtils.mkdir_p("#{@folder}/#{name}")
    CSV.open(file_name(name, version), "a") do |csv|
      csv << [Time.now.to_i, duration, status]
    end
  end

private
  def file_name(name, version)
    "#{@folder}/#{name}/#{version}.csv"
  end
end