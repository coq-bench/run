# Update the CSV database with a new bench suite
require_relative 'database'
require_relative 'opam'
require_relative 'package'
# require_relative 'result'

class Run
  attr_reader :architecture, :packages

  def initialize
    @architecture = {
      os: `uname -s`.strip,
      hardware: `uname -m`.strip,
      ocaml: `ocamlc -version`.strip,
      opam: `opam --version`.strip,
      coq: `opam info --field=version coq`.strip }

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
          if dependency.name.match(/\Acoq-/) then
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
          # Add the result to the CSV database.
          # status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
          # @database.add_bench(package.name, package.version, duration, status)
          # @packages[package.to_s] = [duration, status]
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
end

for repository in [:stable, :testing, :unstable] do
  puts(" \e[1;34mBenching #{repository} repository\e[0m ".center(80, "*"))
  Opam.add_repositories(repository)
  run = Run.new
  run.bench_all
  p run.architecture
  p run.packages
end
