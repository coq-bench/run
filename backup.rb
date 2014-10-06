# Read and update the backup of benchs
require 'csv'
require 'fileutils'

class Backup
  def initialize(folder)
    @folder = folder
  end

  def packages
    Dir.glob(File.join(@folder, "*")).map do |name|
      [File.basename(name),
        Dir.glob(File.join(name, "*")).map do |path|
          File.basename(path, ".csv")
        end]
    end
  end

  def read_history(name, version)
    rows = CSV.read(file_name(name, version)).map do |date, duration, is_success|
      [Time.at(date.to_i), duration.to_i, is_success]
    end
    rows.sort {|x, y| - (x[0] <=> y[0])}
  end

  def add_bench(name, version, duration, is_success)
    FileUtils.mkdir_p(File.join(@folder, name))
    CSV.open(file_name(name, version), "a") do |csv|
      csv << [Time.now.to_i, duration, is_success]
    end
  end

private
  def file_name(name, version)
    File.join(@folder, name, "#{version}.csv")
  end
end