# Update the CSV database with a new bench suite
require_relative 'database'
require_relative 'opam'
require_relative 'package'

class Run
  attr_reader :architecture, :coq_version, :database, :packages

  def initialize(coq_version)
    @architecture = {
      os: `uname -s`.strip,
      hardware: `uname -m`.strip,
      ocaml: `ocamlc -version`.strip,
      opam: `opam --version`.strip }

    @coq_version = coq_version
    @database = nil
    @packages = {}
  end

  # Update the list of Coq packages with a new repository and open a new
  # corresponding database.
  def update_packages_list(repository)
    Opam.add_repositories(repository)
    for package in Opam.all_packages do
      @packages[package] = nil unless @packages.has_key?(package)
    end
    @database = Database.new("database", repository,
      "#{@architecture[:os]}-#{@architecture[:hardware]}-#{@architecture[:ocaml]}-#{@architecture[:opam]}",
      @coq_version)
  end

  # Bench one package.
  def bench(package)
    # Check if the package is already benched.
    if @packages[package].nil? then
      for dependency in package.dependencies_to_install do
        if dependency.name.match(/\Acoq-/) then
          bench(dependency)
        end
      end

      puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

      # Remove a previously installed version, if any
      puts("= Uninstall =".center(80, "-"))
      if Opam.uninstall(package) then
        # Install only the dependencies
        puts("= Dependencies =".center(80, "-"))
        is_success_dependencies = Opam.install_dependencies(package)
        if is_success_dependencies then
          # Install the package itself, and measure total install duration
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
        # Add the result to the CSV database
        status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
        @database.add_bench(package.name, package.version, duration, status)
      else
        puts
      end
    end
  end

  # Bench all the Coq packages.
  def bench_all
    for package, _ in @packages do
      bench(package)
    end
  end
end

Opam.add_repositories(:stable, :testing, :unstable)
coq_versions = Opam.versions("coq")
for coq_version in coq_versions do
  Opam.install(Package.new("coq", coq_version))
  Opam.remove_repositories(:stable, :testing, :unstable)
  run = Run.new(coq_version)
  for repository in [:stable, :testing, :unstable] do
    run.update_packages_list(repository)
    run.bench_all
  end
end
