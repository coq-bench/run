# Handle OPAM actions on a package.
require 'json'
require 'open3'

class Package
  attr_reader :name, :version

  def initialize(name, version)
    @name = name
    @version = version
  end

  def to_s
    "#{@name}.#{@version}"
  end

  # The list of dependencies to install before the package (`nil` if the package
  # cannot be installed), the command, its status, output and JSON output.
  def dependencies_to_install
    output_file = "output.json"
    command = ["opam", "install", "-y", "--json=#{output_file}", "--dry-run",
      to_s]
    logs = run(command)
    file_output = File.read(output_file, encoding: "UTF-8")
    json = JSON.parse(file_output)
    if json == [] then
      dependencies = nil
    else
      to_proceed = json[0]["to-proceed"]
      dependencies = to_proceed.map do |action|
          package = nil
          if action["install"] then
            package = action["install"]
          elsif action["upgrade"] then
            package = action["upgrade"][1]
          elsif action["downgrade"] then
            package = action["downgrade"][1]
          end
          if package then
            dependencies = Package.new(package["name"], package["version"])
          else
            dependencies = nil
          end
        end
        .find_all {|dependency| !dependency.nil? && dependency.to_s != to_s}
    end
    [dependencies, *logs, file_output]
  end

  # Install the dependencies of the package.
  def install_dependencies
    run(["opam", "install", "-y", "--deps-only", to_s])
  end

  # Install the package.
  def install
    run(["opam", "install", "-y", "--verbose", to_s])
  end

  # Run a dummy command.
  def dummy
    run(["true"])
  end

private
  # Run a command and give the return code, the duration and the output.
  def run(command)
    starting_time = Time.now
    output, status = Open3.capture2e(*command)
    duration = (Time.now - starting_time).to_i
    [command.join(" "), status.to_i, duration, output.force_encoding("UTF-8")]
  end
end