require_relative 'backup'

backup = Backup.new("csv")

packages = Dir.glob("../opam-coq-repo/packages/*/*").map do |path|
  File.basename(path)
end

# Compute the results
for package in packages.sort do
  puts "\e[1;34m#{package}:\e[0m"
  system("opam remove -y #{package}")
  puts "---= Dependencies =---"
  is_success_dependencies = system("opam install -y --deps-only #{package}")
  if is_success_dependencies then
    puts "---= Package =---"
    starting_time = Time.now
    is_success = system("opam install -y #{package}")
    duration = (Time.now - starting_time).to_i
    puts
    puts "\e[1mDuration: #{duration} s\e[0m"
    puts
  else
    duration = 0
  end

  name, version = package.split(".", 2)
  status = is_success_dependencies ? (is_success ? "OK" : "Error") : "Deps error"
  backup.add_bench(name, version, duration, status)
end