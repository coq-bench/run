# Handle interactions with OPAM.

class Package
  # The list of versions for a package name.
  def Package.versions(name)
    `opam info --field=available-version,available-versions #{name}`.split(":")[-1].split(",").map {|version| version.strip}
  end

  # The list of all Coq packages.
  def Package.all
    `opam list --unavailable --short --sort "coq-*"`.split(" ").map do |name|
      name = name.strip
      Package.versions(name).map {|version| Package.new(name, version)}
    end.flatten
  end

  attr_reader :name, :version

  def initialize(name, version)
    @name = name
    @version = version
  end

  def to_s
    "#{@name}.#{@version}"
  end

  # The repository of the package. Can be `:stable`, `:testing` or `:unstable`.
  def repository
    case `opam info --field=repository #{self}`.strip
    when "coq"
      :stable
    when "coq-testing"
      :testing
    when "coq-unstable"
      :unstable
    else
      raise "unknown repository"
    end
  end

  # The list of dependencies to install before the package.
  def dependencies_to_install
    `opam install --show-actions #{self}`.split("\n")
      .find_all {|line| line.include?("[required by ")}
      .map do |line|
        name, version = line.match(/ - install   (\S*)/)[1].split(".", 2)
        Package.new(name, version)
      end
  end
end