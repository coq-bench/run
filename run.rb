# Update the CSV database with a new bench suite
require_relative 'database'
require_relative 'opam'
require_relative 'package'

class Run
  def initialize
    @packages = {}
  end

  # Bench one package.
  def bench(package)
    # Check that the package is not already benched or being installed.
    unless @packages.has_key?(package.to_s) then
      @packages[package.to_s] = ["Installing..."]
      dependencies = package.dependencies_to_install

      # First, bench the dependencies.
      unless dependencies.nil? then
        for dependency in dependencies do
          if dependency.name.match(/\Acoq:/) then
            bench(dependency)
          end
        end
      end

      # Display the package name.
      puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

      # Test if it is installable with the current configuration and if Coq
      # itself is not a dependency (should not be the case, except if the
      # current Coq is not compatible with the package).
      if dependencies.nil? ||  dependencies.find {|dependency| dependency.name == "coq"} then
        puts
        puts "\e[1mIncompatible with the current configuration\e[0m"
        puts
        @packages[package.to_s] = ["NotCompatible"]
      else
        # Remove a previously installed version, if any.
        puts("= Uninstall =".center(80, "-"))
        if package.uninstall then
          # Install only the dependencies.
          puts("= Dependencies =".center(80, "-"))
          is_success_dependencies = package.install_dependencies
          if is_success_dependencies then
            # Install the package itself, and measure the total installation duration.
            puts("= Package =".center(80, "-"))
            starting_time = Time.now
            is_success = package.install
            duration = (Time.now - starting_time).to_i
            puts
            puts "\e[1mDuration: #{duration} s\e[0m"
            puts
            @packages[package.to_s] = is_success ?
              ["Success", duration.to_s] :
              ["Error"]
          else
            duration = 0
            puts
            @packages[package.to_s] = ["DepsError"]
          end
        else
          raise "The package #{package} cannot be uninstalled."
        end
      end
    end
  end

  # Bench all the Coq packages.
  def bench_all
    for package in Opam.all_packages do
      bench(package)
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

    for package, result in @packages do
      name, version = package.split(".", 2)
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
  p packages
  exit
  Opam.add_repository("stable")
  run = Run.new
  run.bench_all
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
