# Generate a Dockerfile for a given configuration.
require 'erb'

def puts_usage
  puts "Usage: ruby docker_run.rb jobs ocaml opam coq"
  puts "  jobs: the number of concurrent jobs for compilations"
  puts "  ocaml: 4.01.0, 4.02.1, ..."
  puts "  opam: 1.1.1, 1.2.0, ..."
  puts "  coq: 8.4.5, dev, ..."
end

if ARGV.size == 4 then
  jobs, ocaml, opam, coq = ARGV
  renderer = ERB.new(File.read("Dockerfile.erb", encoding: "UTF-8"))
  File.open("Dockerfile", "w") do |file|
    file << renderer.result()
  end
else
  puts_usage
end
