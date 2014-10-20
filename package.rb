# Handle OPAM actions on a package.

class Package
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
    `opam info --field=repository #{self}`.strip.to_sym
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