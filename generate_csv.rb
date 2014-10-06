# Update the CSV backup with a new bench suite
require_relative 'backup'

backup = Backup.new("csv")

# The package list, computed from the repository directory
packages = Dir.glob("../opam-coq-repo/packages/*/*").map do |path|
  File.basename(path)
end

# Bench each package
for package in packages.sort do
  name, version = package.split(".", 2)
  puts "\e[1;34m#{name} #{version}:\e[0m"

  # Remove a previously installed version, if any
  puts "---= Removing =---"
  if system("opam remove -y #{name}") then
    # Install only the dependencies
    puts "---= Dependencies =---"
    is_success_dependencies = system("opam install -y --deps-only #{package}")
    if is_success_dependencies then
      # Install the package itself, and measure total install duration
      puts "---= Package =---"
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
    # Add the result to the CSV backup
    status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
    backup.add_bench(name, version, duration, status)
  else
    puts
  end
end