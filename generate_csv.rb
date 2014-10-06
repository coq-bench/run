require_relative 'backup'

packages = Dir.glob("../opam-coq-repo/packages/*/*").map do |path|
  File.basename(path)
end

backup = Backup.new("csv")

# Compute the results
for package in packages do
  puts "\e[1;34m#{package}:\e[0m"
  puts "---= Dependencies =---"
  system("opam install -y --deps-only #{package}")
  puts "---= Package =---"
  starting_time = Time.now
  is_success = system("opam install -y #{package}")
  duration = (Time.now - starting_time).to_i
  puts
  puts "\e[1mDuration: #{duration} s\e[0m"
  puts

  name, version = package.split(".", 2)
  backup.add_bench(name, version, duration, is_success ? "OK" : "Error")
end