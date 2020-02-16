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
    run(["opam list; echo; ulimit -Sv 4000000; timeout 2h opam install -y --deps-only #{to_s} coq.#{coq_version}"])
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
      "coq-geocoq-main",
      "coq-iris",
      "coq-mathcomp-field",
      "coq-mathcomp-odd-order",
      "coq-qcert",
      "coq-vst"
    ]
    timeout = very_slow_packages.include?(@name) ? "10h" : (slow_packages.include?(@name) ? "4h" : "2h")
    run([
      "opam list; echo; ulimit -Sv 16000000; " +
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
    output = "" if status.to_i == 0
    output_lines = output.split("\n")
    max_lines = 1_000
    if output_lines.size > max_lines then
      output = "#{output_lines[0..(max_lines / 2 - 1)].join("\n")}\n\n[...] truncated\n\n#{output_lines[- (max_lines / 2)..-1].join("\n")}\n\nThe middle of the output is truncated (maximum #{max_lines} lines)\n"
    end
    duration = (Time.now - starting_time).to_i
    [command.join(" "), status.to_i, duration, output]
  end
end
