# Update the CSV backup of benchmarks
require 'csv'
require 'fileutils'

# A view of the database for a specific repository, architecture and Coq version
class Database
  def initialize(folder, architecture, coq, repository)
    @folder = folder
    @architecture = architecture
    @coq = coq
    @repository = repository
  end

  def add_bench(name, version, result)
    FileUtils.mkdir_p(folder_name(name))
    CSV.open(file_name(name, version), "a") do |csv|
      csv << [Time.now.to_i] + result
    end
  end

private
  def folder_name(name)
    "#{@folder}/#{@architecture}/#{@coq}/#{@repository}/#{name}"
  end

  def file_name(name, version)
    "#{folder_name(name)}/#{version}.csv"
  end
end