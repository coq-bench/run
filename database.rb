# Update the CSV backup of benchmarks
require 'csv'
require 'fileutils'

# A view of the database for a specific repository, architecture and Coq version
class Database
  def initialize(folder, repository, architecture, coq)
    @folder = folder
    @repository = repository
    @architecture = architecture
    @coq = coq
  end

  def add_bench(name, version, duration, status)
    FileUtils.mkdir_p(folder_name(name))
    CSV.open(file_name(name, version), "a") do |csv|
      csv << [Time.now.to_i, duration, status]
    end
  end

private
  def folder_name(name)
    "#{@folder}/#{@repository}/#{@architecture}/#{@coq}/#{name}"
  end

  def file_name(name, version)
    "#{folder_name(name)}/#{version}.csv"
  end
end