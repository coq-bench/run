# Handle opam actions on a package.
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

  # Disabled since opam 2.
  def lint
    run("true")
  end

  def dry_install_with_coq
    run("opam install -y --show-action #{to_s} coq.#{coq_version}")
  end

  def dry_install_without_coq
    run("opam remove -y coq; opam install -y --show-action --unlock-base #{to_s}")
  end

  # Install the dependencies of the package.
  def install_dependencies
    slow_packages = [
      "coq-geocoq",
      "coq-geocoq-pof"
    ]
    timeout = slow_packages.include?(@name) ? "8h" : "4h"
    run(
      "opam list; echo; " +
      "timeout #{timeout} opam install -y --deps-only #{to_s} coq.#{coq_version}"
    )
  end

  # Install the package.
  def install
    very_slow_packages = [
      "coq-intuitionistic-nuprl",
      "coq-vst"
    ]
    slow_packages = [
      "coq-areamethod",
      "coq-ceramist",
      "coq-color",
      "coq-compcert",
      "coq-corn",
      "coq-geocoq",
      "coq-geocoq-main",
      "coq-iris",
      "coq-mathcomp-field",
      "coq-mathcomp-odd-order",
      "coq-qcert",
      "coq-unimath"
    ]
    timeout = very_slow_packages.include?(@name) ? "20h" : (slow_packages.include?(@name) ? "8h" : "4h")
    run(
      "opam list; echo; " +
      "timeout #{timeout} opam install -y#{@repository == "released" ? " -v" : ""} #{to_s} coq.#{coq_version}"
    )
  end

  # Remove the package.
  def remove
    run("opam remove -y #{to_s}")
  end

  # Run a dummy command.
  def dummy
    run("true")
  end

  # Fail with an error message.
  def fail(message)
    run("echo #{message}; false")
  end

private
  # Run a command and give the return code, the duration and the output. Give an
  # empty output on success.
  def run(command)
    starting_time = Time.now
    output, status = Open3.capture2e("bash", "-c", command)
    output = "" if status.to_i == 0
    output = output.force_encoding(Encoding::UTF_8)
    max_characters = 20_000
    if output.size > max_characters then
      output = "#{output[0..(max_characters / 2 - 1)]}\n\n[...] truncated\n\n#{output[- (max_characters / 2)..-1]}\n\nThe middle of the output is truncated (maximum #{max_characters} characters)\n"
    end
    duration = (Time.now - starting_time).to_i
    [command, status.to_i, duration, output]
  end
end
