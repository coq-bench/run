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

  def coq_version
    `opam info --field=version coq`.strip
  end

  def path
    "opam-coq-archive/#{@repository}/packages/#{name}/#{name}.#{version}"
  end

  def lint
    # We temporarily disable the linter for OPAM 2.
    #run(["ruby", "lint.rb", @repository, path])
    run(["true"])
  end

  def dry_install_with_coq
    run(["opam", "install", "-y", "--show-action", to_s, "coq.#{coq_version}"])
  end

  def dry_install_without_coq
    run(["opam remove -y coq; opam install -y --show-action --unlock-base #{to_s}"])
  end

  # Install the dependencies of the package.
  def install_dependencies
    slow_packages = [
      "coq-infotheo",
      "coq-interval",
      "coq-libvalidsdp",
      "coq-mathcomp-analysis",
      "coq-mathcomp-character",
      "coq-mathcomp-field-extra",
      "coq-mathcomp-odd-order",
      "coq-mathcomp-real-closed",
      "coq-mathcomp-sum-of-two-square",
      "coq-monae",
      "coq-pi-agm"
    ]
    timeout = slow_packages.include?(@name) ? "300m" : "60m"
    run(["opam list; echo; ulimit -Sv 4000000; timeout #{timeout} opam install -y --deps-only #{to_s} coq.#{coq_version}"])
  end

  # Install the package.
  def install
    very_slow_packages = [
      "coq-intuitionistic-nuprl"
    ]
    slow_packages = [
      "coq-areamethod",
      "coq-color",
      "coq-compcert",
      "coq-corn",
      "coq-geocoq",
      "coq-iris",
      "coq-mathcomp-field",
      "coq-mathcomp-odd-order",
      "coq-qcert",
      "coq-vst"
    ]
    timeout = very_slow_packages.include?(@name) ? "10h" : slow_packages.include?(@name) ? "2h" : "1h"
    run([
      "opam list; echo; ulimit -Sv 4000000; " +
      "timeout #{timeout} opam install -y#{@repository == "released" ? " -v" : ""} #{to_s} coq.#{coq_version}"
    ])
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
    max_characters = 100_000
    if output.size > max_characters then
      output = "#{output[0..(max_characters - 1)]}\n[...]\nTruncated (maximum #{max_characters})\n"
    end
    duration = (Time.now - starting_time).to_i
    [command.join(" "), status.to_i, duration, output]
  end
end
