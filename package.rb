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

  # Test if a package can be installed with the current configuration.
  def is_installable?
    system("opam install --dry-run #{self}") == 0
  end

  # The list of dependencies to install before the package.
  def dependencies_to_install
    # p `opam install --show-actions #{self}`.split("\n")
    #   .find_all {|line| line.include?("[required by ")}
    `opam install --show-actions #{self}`.split("\n")
      .find_all {|line| line.include?("[required by ")}
      .map do |line|
        name, version = line.match(/ - \w+   (\S*)/)[1].split(".", 2)
        Package.new(name, version)
      end
  end
end