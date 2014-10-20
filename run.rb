# Update the CSV database with a new bench suite
require_relative 'database'

# Architecture
architecture = {
  os: `uname -s`.strip,
  hardware: `uname -m`.strip,
  ocaml: `ocamlc -version`.strip,
  opam: `opam --version`.strip }
p architecture

class Package
  # The list of versions for a package name.
  def Package.versions(name)
    `opam info --field=available-version,available-versions #{name}`.split(":")[-1].split(",").map {|version| version.strip}
  end

  # The list of all Coq packages.
  def Package.all
    `opam list --unavailable --short --sort "coq-*"`.split(" ").map do |name|
      name = name.strip
      Package.versions(name).map {|version| Package.new(name, version)}
    end.flatten
  end

  attr_reader :name, :version

  def initialize(name, version)
    @name = name
    @version = version
  end

  def to_s
    "#{@name}.#{@version}"
  end

  # The repository of the package. Can be `:stable`, `:testing` or `:unstable`.
  def repository
    case `opam info --field=repository #{self}`.strip
    when "coq"
      :stable
    when "coq-testing"
      :testing
    when "coq-unstable"
      :unstable
    else
      raise "unknown repository"
    end
  end

  # # The list of dependencies with a specific pattern.
  # def dependencies_with_pattern(pattern)
  #   `opam list --unavailable --sort --required-by=#{self} --recursive #{pattern.inspect}`.split("\n")
  #     .find_all {|line| line[0] != "#" && line != "No packages found."}
  #     .map do |dependency|
  #       name, version = dependency.split(" ")[0..1].map {|s| s.strip}
  #       Package.new(name, version)
  #     end
  # end

  # # The Coq version of the package.
  # def coq
  #   dependencies_with_pattern("coq")
  # end

  # # The list of dependencies which are Coq packages.
  # def dependencies
  #   dependencies_with_pattern("coq-*")
  # end

  def dependencies_to_install
    `opam install --show-actions #{self}`.split("\n")
      .find_all {|line| line.include?("[required by ")}
      .map do |line|
        name, version = line.match(/ - install   (\S*)/)[1].split(".", 2)
        Package.new(name, version)
      end
  end
end

# Coq versions
p Package.versions("coq")

# Packages
packages = {}
for package in Package.all do
  packages[package] = nil
end
puts packages
puts
# for package in packages do
#   puts "#{package}: #{package.coq}"
# end
# puts
# for package in packages do
#   puts "#{package}: #{package.dependencies}"
# end
# puts
# for package, _ in packages do
#   puts "#{package}: #{package.dependencies_to_install}"
# end

def bench(package)
  for dependency in package.dependencies_to_install do
    if dependency.name.match(/\Acoq-/) then
      bench(dependency)
    end
  end
  puts "benching #{package}"
end

for package, _ in packages do
  bench(package)
end

exit(0)

# database = Database.new("database")

# The package list, computed from the repository directory
packages = Dir.glob("../opam-coq-repo/packages/*/*").map do |path|
  File.basename(path)
end

# Bench each package
for package in packages.sort do
  name, version = package.split(".", 2)
  puts "\e[1;34m#{name} #{version}:\e[0m"

  # Remove a previously installed version, if any
  puts("= Removing =".center(80, "-"))
  if system("opam remove -y #{name}") then
    # Install only the dependencies
    puts("= Dependencies =".center(80, "-"))
    is_success_dependencies = system("opam install -y --deps-only #{package}")
    if is_success_dependencies then
      # Install the package itself, and measure total install duration
      puts("= Package =".center(80, "-"))
      starting_time = Time.now
      is_success = system("opam install -y #{package}")
      duration = (Time.now - starting_time).to_i
      puts
      puts "\e[1mDuration: #{duration} s\e[0m"
      puts
    else
      duration = 0
      puts
    end
    # Add the result to the CSV database
    status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
    database.add_bench(name, version, duration, status)
  else
    puts
  end
end