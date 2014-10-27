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

  # The list of dependencies to install before the package, `nil` if the package
  # cannot be installed.
  def dependencies_to_install
    output_file = "output.json"
    # We do a `popen3` so no value are displayed on the terminal.
    Open3.popen3("opam", "install", "--root=.opam_run", "-y", "--json=#{output_file}", "--dry-run", to_s) do |_, _, _, process|
      process.value
    end
    output = JSON.parse(File.read(output_file))
    if output == [] then
      nil
    else
      to_proceed = output[0]["to-proceed"]
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
            Package.new(package["name"], package["version"])
          else
            nil
          end
        end
        .find_all {|dependency| !dependency.nil? && dependency.to_s != to_s}
    end
  end

  # Install the dependencies of the package.
  def install_dependencies
    system("opam", "install", "--root=.opam_run", "-y", "--deps-only", to_s)
  end

  # Install the package.
  def install
    system("opam", "install", "--root=.opam_run", "-y", to_s)
  end
end