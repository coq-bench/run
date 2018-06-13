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
    run(["ruby", "lint.rb", @repository, "opam-coq-archive/#{@repository}/packages/#{name}/#{name}.#{version}"])
  end

  def dry_install_with_coq
    coq_version = `opam info --field=version coq`.strip
    run(["opam", "install", "-y", "--show-action", to_s, "coq.#{coq_version}"])
  end

  def dry_install_without_coq
    run(["opam remove -y coq; opam install -y --show-action #{to_s}"])
  end

  # Install the dependencies of the package.
  def install_dependencies
    run(["opam list; ulimit -Sv 4000000; timeout 30m opam install -y --deps-only #{to_s}"])
  end

  # Install the package.
  def install
    slow_packages = [
      "coq-areamethod",
      "coq-color",
      "coq-compcert",
      "coq-geocoq"
    ]
    timeout = slow_packages.include?(@name) ? "400m" : "30m"
    run(["opam list; ulimit -Sv 4000000; timeout #{timeout} opam install -j1 -y -v #{to_s}"])
  end

  # Remove the package.
  def remove
    run(["opam", "remove", "-y", to_s])
  end

  # Run a dummy command.
  def dummy
    run(["true"])
  end

  # Fail with an error message.
  def fail(message)
    run(["echo #{message}; false"])
  end

private
  # Run a command and give the return code, the duration and the output. Give an
  # empty output on success.
  def run(command)
    starting_time = Time.now
    output, status = Open3.capture2e(*command)
    # 124 is the timeout status.
    output = "" if status.to_i == 0 || status.to_i == 124
    duration = (Time.now - starting_time).to_i
    [command.join(" "), status.to_i, duration, output]
  end
end
