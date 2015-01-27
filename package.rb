# Handle OPAM actions on a package.
require 'json'
require 'open3'

class Package
  attr_reader :name, :version

  def initialize(repository, name, version)
    @repository = repository
    @name = name
    @version = version
  end

  def to_s
    "#{@name}.#{@version}"
  end

  def lint
    run(["ruby", "lint.rb", @repository, "../#{@repository}/packages/#{name}/#{name}.#{version}"])
  end

  def dry_install_with_coq
    coq_version = `opam info --field=version coq`.strip
    run(["opam", "install", "-y", "--dry-run", to_s, "coq.#{coq_version}"])
  end

  def dry_install_without_coq
    run(["opam remove -y coq; opam install -y --dry-run #{to_s}"])
  end

  # Install the dependencies of the package.
  def install_dependencies
    run(["ulimit -Sv 2000000; opam install -y --deps-only #{to_s}"])
  end

  # Install the package.
  def install
    run(["ulimit -Sv 2000000; opam install -y --verbose #{to_s}"])
  end

  # Remove the package.
  def remove
    run(["opam", "remove", "-y", to_s])
  end

  # Run a dummy command.
  def dummy
    run(["true"])
  end

private
  # Run a command and give the return code, the duration and the output.
  def run(command)
    starting_time = Time.now
    output, status = Open3.capture2e(*command)
    duration = (Time.now - starting_time).to_i
    [command.join(" "), status.to_i, duration, output.force_encoding("UTF-8")]
  end
end
