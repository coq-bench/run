# Run the benches.
require 'erb'

def puts_usage
  puts "Usage: ruby run.rb jobs ocaml opam database"
  puts "  jobs: the number of concurrent jobs for compilations"
  puts "  ocaml: 4.01.0, 4.02.1, ..."
  puts "  opam: 1.1.1, 1.2.0, ..."
  puts "  database: path to a folder to store the generated CSV files"
end

if ARGV.size == 4 then
  jobs, ocaml, opam, database = ARGV
else
  puts_usage
  exit(1)
end

# Generate the Dockerfile.
renderer = ERB.new(File.read("Dockerfile.erb", encoding: "UTF-8"))
File.open("Dockerfile", "w") do |file|
  file << renderer.result()
end

# Run the Dockerfile.
system("docker build --tag=run . && docker run --privileged -ti -v #{File.expand_path(database)}:/home/bench/database run ruby loop.rb #{ocaml}")
