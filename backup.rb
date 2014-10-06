# Read and update the backup of benchs
require 'csv'

class Backup
  def initialize(folder)
    @folder = folder
  end

  def packages
    Dir.glob(File.join(@folder, "*")).map do |name|
      [File.basename(name),
        Dir.glob(File.join(@folder, "*", "*")).map do |path|
          File.basename(path, ".csv")
        end]
    end
  end

  def read_history(name, version)
    CSV.read(file_name(name, version)).map do |date, duration, is_success|
      [Time.at(date.to_i), duration.to_i, (is_success == "OK")]
    end
  end

private
  def file_name(name, version)
    File.join(@folder, name, "#{version}.csv")
  end
end