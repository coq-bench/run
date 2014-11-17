def puts_usage
  puts "Usage: ruby lint.rb repo folder"
  puts "  repo: stable, testing or unstable"
  puts "  folder: the folder of a package"
end

def lint(repository, folder)
  name, version = File.basename(folder).split(".", 2)
  descr = File.read(File.join(folder, "descr"), encoding: "UTF-8")
  opam = File.read(File.join(folder, "opam"), encoding: "UTF-8")
  url = File.read(File.join(folder, "url"), encoding: "UTF-8")

  begin
    unless name.match(/\A[a-z:\-]+\z/) then
      raise "Wrong name #{name.inspect}, expected only small caps (a-z), dashes or colons (-, :)."
    end
    unless descr.strip[-1] == "." then
      raise "The description should end by a dot (.) to ensure uniformity."
    end
    unless opam.match("%{jobs}%") then
      raise "The build script should use the `%{jobs}%` variable to speedup building time. For example:
build: [
  [make \"-j%{jobs}%\"]
  [make \"install\"]
]"
    end
    unless opam.match("license:") then
      raise "You should specify the license to make your package public, if possible an open-source one. For example:
license: \"MIT\""
    end

    # Checks specific to the stable repository.
    unless repository != "stable" then
      unless version.match(/\A[0-9]+\.[0-9]+\.[0-9]+\z/) then
        raise "Wrong stable version name #{version.inspect}, expected three numbers separated by dots."
      end
      unless url.match("checksum") then
        raise "Checksum expected for the archive."
      end
    end
  rescue Exception => e
    puts e
    exit(1)
  end
end

if ARGV.size == 2 then
  lint(*ARGV)
else
  puts_usage
  exit(1)
end
