# Update the CSV database with a new bench suite
require_relative 'database'
require_relative 'opam'
require_relative 'package'

class Run
  attr_reader :architecture, :coq_version, :packages

  def initialize(coq_version)
    @architecture = {
      os: `uname -s`.strip,
      hardware: `uname -m`.strip,
      ocaml: `ocamlc -version`.strip,
      opam: `opam --version`.strip }

    @coq_version = coq_version
    # @database = nil
    @packages = {}
  end

  # Update the list of Coq packages with a new repository and open a new
  # corresponding database.
  def update_packages_list(repository)
    Opam.add_repositories(repository)
    for package in Opam.all_packages do
      @packages[package] = nil unless @packages.has_key?(package)
    end
    # @database = Database.new("database", repository,
    #   "#{@architecture[:os]}-#{@architecture[:hardware]}-#{@architecture[:ocaml]}-#{@architecture[:opam]}",
    #   @coq_version)
  end

  # Bench one package.
  def bench(package)
    # Check if the package is already benched.
    if @packages[package].nil? then
      dependencies = package.dependencies_to_install

      # First, bench the dependencies.
      for dependency in dependencies do
        if dependency.name.match(/\Acoq-/) then
          bench(dependency)
        end
      end

      # Display the package name.
      puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

      # Test if Coq itseld is a dependency (should not be the case, except if
      # the current Coq version is not compatible) and if it is installable with
      # the current configuration.
      if dependencies.find {|dependency| dependency.name == "coq"} || !package.is_installable? then
        @packages[package] = "incompatible"
        puts
        puts "\e[1mIncompatible with the current configuration\e[0m"
        puts
      else
        # Remove a previously installed version, if any.
        puts("= Uninstall =".center(80, "-"))
        if Opam.uninstall(package) then
          # Install only the dependencies.
          puts("= Dependencies =".center(80, "-"))
          is_success_dependencies = Opam.install_dependencies(package)
          if is_success_dependencies then
            # Install the package itself, and measure total install duration.
            puts("= Package =".center(80, "-"))
            starting_time = Time.now
            is_success = Opam.install(package)
            duration = (Time.now - starting_time).to_i
            puts
            puts "\e[1mDuration: #{duration} s\e[0m"
            puts
          else
            duration = 0
            puts
          end
          # Add the result to the CSV database.
          status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
          # @database.add_bench(package.name, package.version, duration, status)
          @packages[package] = [duration, status]
        else
          puts
        end
      end
    end
  end

  # Bench all the Coq packages.
  def bench_all
    for package in @packages.keys do
      bench(package)
    end
  end
end

Opam.add_repositories(:stable, :testing, :unstable)
coq_versions = Opam.versions("coq")
for coq_version in coq_versions do
  puts(" \e[1;34mBenching Coq #{coq_version}\e[0m ".center(80, "*"))
  Opam.install(Package.new("coq", coq_version))
  Opam.remove_repositories(:stable, :testing, :unstable)
  run = Run.new(coq_version)
  for repository in [:stable, :testing, :unstable] do
    run.update_packages_list(repository)
    run.bench_all
    p run.packages
  end
end
