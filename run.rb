# Update the CSV database with a new bench suite
require_relative 'database'

# Architecture
architecture = {
  :os => `uname -s`.strip,
  :hardware => `uname -m`.strip,
  :ocaml => `ocamlc -version`.strip,
  :opam => `opam --version`.strip }
p architecture

# Coq versions
coqs = `opam info --field=available-versions coq`.split(",").map {|coq| coq.strip}
p coqs

exit(0)

# database = Database.new("csv")

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