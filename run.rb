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

      # Initialize result variables.
      dry_logs_with_coq = package.dummy
      dry_logs_without_coq = package.dummy
      deps_logs = package.dummy
      package_logs = package.dummy
      uninstall_logs = package.dummy
      missing_removes = mistake_removes = []

      # Copy the `~/.opam_backup` folder to `~/.opam`.
      system("rsync -a --delete ~/.opam_backup/ ~/.opam")

      # Display the list of installed packages (should be almost empty).
      system("opam", "list")

      # Run a dry install with the current coq.
      dry_logs_with_coq = package.dry_install_with_coq
      puts dry_logs_with_coq[3]
      puts
      # Test if the package is not installable.
      if dry_logs_with_coq[1] != 0 then
        # Test if the package can be installed without the current Coq.
        dry_logs_without_coq = package.dry_install_without_coq
        puts dry_logs_without_coq[3]
        if dry_logs_without_coq[1] == 0 then
          puts
          puts "\e[1mIncompatible with the current Coq version.\e[0m"
          result = "NotCompatible"
        else
          puts
          puts "\e[1mThe dependencies cannot be resolved.\e[0m"
          result = "DepsError"
        end
      else
        # Install only the dependencies.
        puts "Dependencies..."
        deps_logs = package.install_dependencies
        if deps_logs[1] == 0 then
          def list_files
            opam_root_folder = "#{Dir.home}/.opam/#{`opam switch show`.strip}"
            Dir.glob("#{opam_root_folder}/**/*") - Dir.glob("#{opam_root_folder}/reinstall")
          end
          files_before = list_files
          # Install the package itself.
          puts "Package..."
          package_logs = package.install
          puts
          if package_logs[1] == 0 then
            # Uninstall the package.
            uninstall_logs = package.remove
            files_after = list_files
            missing_removes = files_after - files_before
            mistake_removes = files_before - files_after
            if uninstall_logs[1] == 0 && missing_removes + mistake_removes == [] then
              puts "\e[1mTotal duration: #{deps_logs[2] + package_logs[2]} s.\e[0m"
              result = "Success"
            else
              puts "\e[1mError with the uninstallation.\e[0m"
              result = "UninstallError"
            end
          else
            puts "\e[1mError with the package.\e[0m"
            result = "Error"
          end
        else
          puts
          puts "\e[1mError in installation of the dependencies.\e[0m"
          result = "DepsError"
        end
      end
      @results << [package.name, package.version, result,
        *dry_logs_with_coq, *dry_logs_without_coq, *deps_logs, *package_logs,
        *uninstall_logs, missing_removes.join("\n"), mistake_removes.join("\n")]
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
      "Dry with Coq command", "Dry with Coq status", "Dry with Coq duration", "Dry with Coq output",
      "Dry without Coq command", "Dry without Coq status", "Dry without Coq duration", "Dry without Coq output",
      "Deps command", "Deps status", "Deps duration", "Deps output",
      "Package command", "Package status", "Package duration", "Package output",
      "Uninstall command", "Uninstall status", "Uninstall duration", "Uninstall output",
      "Missing removes", "Mistake removes"]
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
  # List all packages.
  packages = Opam.all_packages(repositories)
  puts "Packages to bench:"
  for package in packages do
    puts "- #{package.name} #{package.version}"
  end
  # Make a new bench object.
  run = Run.new(packages)
  # Add the repositories.
  for repository in repositories do
    Opam.add_repository(repository)
  end
  # Save the `~/.opam` folder to `~/.opam_backup`.
  save_command = "cp -R ~/.opam ~/.opam_backup"
  puts save_command
  system(save_command)
  # Run the bench.
  run.bench
  # Save the results to the database.
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
