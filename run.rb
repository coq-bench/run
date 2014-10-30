# Update the CSV database with a new bench suite.
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
      puts
      puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

      # Copy the `~/.opam_backup` folder to `~/.opam`.
      system("rsync -a --delete ~/.opam_backup/ ~/.opam")

      # Display the list of installed packages (should be almost empty).
      system("opam list --root=~/.opam")

      # Run a dry install to compute the dependencies.
      dependencies, *dry_logs = package.dependencies_to_install
      puts dry_logs[3]
      puts

      # Test if the package is not installable.
      if dependencies.nil?
        puts
        puts "\e[1mThe dependencies cannot be resolved.\e[0m"
        deps_logs = package.dummy
        package_logs = package.dummy
        result = "DepsError"
      # Test if the current Coq is not compatible with the package.
      elsif dependencies.find {|dependency| dependency.name == "coq"} then
        puts
        puts "\e[1mIncompatible with the current configuration.\e[0m"
        deps_logs = package.dummy
        package_logs = package.dummy
        result = "NotCompatible"
      else
        # Install only the dependencies.
        puts "Dependencies..."
        deps_logs = package.install_dependencies
        if deps_logs[1] == 0 then
          # Install the package itself.
          puts "Package..."
          package_logs = package.install
          puts
          if package_logs[1] == 0 then
            puts "\e[1mDuration: #{package_logs[2]} s.\e[0m"
            result = "Success"
          else
            puts "\e[1mError with the package.\e[0m"
            result = "Error"
          end
        else
          puts
          puts "\e[1mError in installation of the dependencies.\e[0m"
          package_logs = package.dummy
          result = "DepsError"
        end
      end
      @results << [package.name, package.version, result,
        *dry_logs, *deps_logs, *package_logs]
    end
  end

  # Save the results of the bench to the database.
  def write_to_database(repository)
    os = `uname -s`.strip
    hardware = `uname -m`.strip
    ocaml = `ocamlc -version`.strip
    opam = `opam --version`.strip
    coq = `opam info --field=version coq`.strip
    database = Database.new("../database", "#{os}-#{hardware}-#{ocaml}-#{opam}", repository, coq, Time.now)

    titles = ["Name", "Version", "Status",
      "Dry command", "Dry status", "Dry duration", "Dry output", "Dry JSON",
      "Deps command", "Deps status", "Deps duration", "Deps output",
      "Package command", "Package status", "Package duration", "Package output"]
    database.add_bench(titles)
    for result in @results do
      database.add_bench(result)
    end
  end
end

def puts_usage
  puts "Usage: ruby run.rb repo"
  puts "  stable: the stable repository"
  puts "  testing: the testing repository"
  puts "  unstable: the unstable repository"
end

def run(repository, repositories)
  puts "\e[1;34mBenching the #{repository} repository:\e[0m"
  packages = Opam.all_packages(repositories)
  puts "Packages to bench:"
  for package in packages do
    puts "- #{package.name} #{package.version}"
  end
  run = Run.new(packages)
  for repository in repositories do
    Opam.add_repository(repository)
  end
  # Save the `~/.opam` folder in `.opam_backup`.
  system("cp -R ~/.opam ~/.opam_backup")
  run.bench
  run.write_to_database(repository)
end

case ARGV[0]
when "-h", "--help", "help"
  puts_usage
  exit(0)
when "stable"
  run("stable", ["stable"])
when "testing"
  run("testing", ["stable", "testing"])
when "unstable"
  run("unstable", ["stable", "testing", "unstable"])
else
  puts_usage
  exit(1)
end
