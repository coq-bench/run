# Update the CSV database with a new bench suite
require 'fileutils'
require_relative 'database'
require_relative 'opam'
require_relative 'package'

class Run
  def initialize(packages)
    @packages = packages
    @results = []
  end

  # Bench the packages.
  def bench
    for package in @packages do
      # Display the package name.
      puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

      # Copy the `.opam` folder to `.opam_run`.
      system("rsync", "-a", "--delete", ".opam/", ".opam_run")
      dependencies = package.dependencies_to_install

      # Test if the package is not installable.
      if dependencies.nil?
        puts
        puts "\e[1mThe dependencies cannot be resolved.\e[0m"
        puts
        result = ["DepsError"]
      # Test if the current Coq is not compatible with the package.
      elsif dependencies.find {|dependency| dependency.name == "coq"} then
        puts
        puts "\e[1mIncompatible with the current configuration.\e[0m"
        puts
        result = ["NotCompatible"]
      else
        # Install only the dependencies.
        puts("= Dependencies =".center(80, "-"))
        if package.install_dependencies then
          # Install the package itself, and measure the total installation duration.
          puts("= Package =".center(80, "-"))
          starting_time = Time.now
          is_success = package.install
          duration = (Time.now - starting_time).to_i
          puts
          puts "\e[1mDuration: #{duration} s.\e[0m"
          puts
          result = is_success ? ["Success", duration.to_s] : ["Error"]
        else
          puts
          puts "\e[1mError in installation of the dependencies.\e[0m"
          puts
          result = ["DepsError"]
        end
      end
      @results << [package.name, package.version, result]
    end
  end

  # Save the results of the bench to the database.
  def write_to_database(repository)
    os = `uname -s`.strip
    hardware = `uname -m`.strip
    ocaml = `ocamlc -version`.strip
    opam = `opam --version`.strip
    coq = `opam info --field=version coq`.strip
    database = Database.new("database", "#{os}-#{hardware}-#{ocaml}-#{opam}", repository, coq)

    for name, version, result in @results do
      database.add_bench(name, version, result)
    end
  end
end

def puts_usage
  puts "Usage: ruby run.rb repo"
  puts "  stable: the stable repository"
  puts "  testing: the testing repository"
  puts "  unstable: the unstable repository"
end

case ARGV[0]
when "-h", "--help", "help"
  puts_usage
  exit(0)
when "stable"
  packages = Opam.all_packages(["stable"])
  puts "Packages to bench:"
  for package in packages do
    puts "- #{package.name} #{package.version}"
  end
  run = Run.new(packages)
  Opam.add_repository("stable")
  run.bench
  run.write_to_database("stable")
else
  puts_usage
  exit(1)
end

# for repository in [:stable, :testing, :unstable] do
#   puts(" \e[1;34mBenching #{repository} repository\e[0m ".center(80, "*"))
#   Opam.add_repository(repository)
#   run = Run.new
#   run.bench_all
#   run.write_to_database(repository)
# end
