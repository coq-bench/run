# Update the CSV database with a new bench suite
require_relative 'database'
require_relative 'package'

class Run
  attr_reader :architecture

  def initialize
    @architecture = {
      os: `uname -s`.strip,
      hardware: `uname -m`.strip,
      ocaml: `ocamlc -version`.strip,
      opam: `opam --version`.strip }

    @database = Database.new("database", "all",
      "#{architecture[:os]}-#{architecture[:hardware]}-#{architecture[:ocaml]}-#{architecture[:opam]}",
      "8.4pl4")

    @packages = {}
    for package in Package.all do
      @packages[package] = nil
    end
  end

  # Bench one package.
  def bench(package)
    for dependency in package.dependencies_to_install do
      if dependency.name.match(/\Acoq-/) then
        bench(dependency)
      end
    end

    puts "\e[1;34m#{package.name} #{package.version}:\e[0m"

    # Remove a previously installed version, if any
    puts("= Uninstall =".center(80, "-"))
    if system("opam remove -y #{package.name}") then
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
      @database.add_bench(package.name, package.version, duration, status)
    else
      puts
    end
  end

  # Bench all packages.
  def bench_all
    for package, _ in @packages do
      bench(package)
    end
  end
end

# Coq versions
p Package.versions("coq")

Run.new.bench_all