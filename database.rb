# Update the CSV backup of benchmarks
require 'csv'
require 'fileutils'

# A view of the database for a specific architecture, repository, Coq and time.
class Database
  def initialize(folder, architecture, repository, coq, time)
    @folder = folder
    @architecture = architecture
    @repository = repository
    @coq = coq
    @time = time
  end

  def add_bench(result)
    FileUtils.mkdir_p(folder_name)
    CSV.open(file_name, "a", encoding: "UTF-8") do |csv|
      puts "Adding #{result.inspect} #{result}"
      csv << result
    end
  end

private
  def folder_name
    "#{@folder}/#{@architecture}/#{@repository}/#{@coq}"
  end

  def file_name
    "#{folder_name}/#{@time.utc.strftime("%F_%T")}.csv"
  end
end