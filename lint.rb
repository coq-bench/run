# Check that packages are well-formed.

def puts_usage
  puts "Usage: ruby lint.rb repo folder"
  puts "  repo: released or extra-dev"
  puts "  folder: the folder of a package"
end

def lint(repository, folder)
  name, version = File.basename(folder).split(".", 2)
  descr = File.read(File.join(folder, "descr"), encoding: "binary")
  opam = File.read(File.join(folder, "opam"), encoding: "binary")
  url = File.read(File.join(folder, "url"), encoding: "binary")

  # OPAM lint.
  unless system("opam lint #{folder}") then
    exit(1)
  end

  # Custom lint.
  begin
    unless name.match(/\Acoq\-/) then
      raise "The package name should start with \"coq-\"."
    end
    unless name.match(/\A[a-z0-9:\-_]+\z/) then
      raise "Wrong name #{name.inspect}, expected only small caps (a-z), digits (0-9), dashes, underscores or colons (-, _, :)."
    end
    unless opam.match("homepage:") then
      raise "You should add an homepage for your package. For example:
homepage: \"https://github.com/user/project\""
    end
    unless opam.match("license:") then
      raise "You should specify the license to make your package public, if possible an open-source one. For example:
license: \"MIT\""
    end

    # Specific checkes for the released repository.
    if repository == "released" then
      unless url.match("checksum") then
        raise "A checksum is expected for the archive."
      end
    end

    puts "The package is valid."
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
