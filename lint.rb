def puts_usage
  puts "Usage: ruby lint.rb repo folder"
  puts "  repo: stable, testing or unstable"
  puts "  folder: the folder of a package"
end

def lint(repository, folder)
  name, version = File.basename(folder).split(".", 2)
  unless name.match(/\A[a-z:\-]+\z/) then
    puts "Wrong name #{name.inspect}, expected only small caps (a-z), dashes or colons (-, :)."
    exit(1)
  end
  unless repository != "stable" || version.match(/\A[0-9]+\.[0-9]+\.[0-9]+\z/) then
    puts "Wrong stable version name #{version.inspect}, expected three numbers separated by dots."
  end
end

if ARGV.size == 2 then
  lint(*ARGV)
else
  puts_usage
  exit(1)
end
