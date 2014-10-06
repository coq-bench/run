results = {}

packages = Dir.glob("../opam-coq-repo/packages/*/*").map do |path|
  File.basename(path)
end

# Compute the results
for package in packages do
  puts "\e[1;34m#{package}:\e[0m"
  puts "---= Dependencies =---"
  system("opam install -y --deps-only #{package}")
  puts "---= Package =---"
  starting_time = Time.now
  is_installed = system("opam install -y #{package}")
  duration = Time.now - starting_time
  results[package] = [is_installed, duration]
  puts
  puts "\e[1mDuration: #{duration.to_i} s\e[0m"
  puts
end