# Handle interactions with OPAM.
require_relative 'package'

module Opam
  # Coq repositories.
  def Opam.repositories
    { stable: "https://github.com/coq/opam-coq-repo.git",
      testing: "https://github.com/coq/opam-coq-repo-testing.git",
      unstable: "https://github.com/coq/opam-coq-repo-unstable.git" }
  end

  # The list of versions for a package name. The package must first be uninstalled.
  def Opam.versions(name)
    versions = `opam info --field=available-version,available-versions #{name}`.split(":")[-1]
    versions.split(",").map {|version| version.strip}
  end

  # The list of all Coq packages, in a reverse "dependencies" order.
  # Be cautious, it starts by removing all the installed Coq packages. It does
  # that so it is simpler to list all the available versions for each package.
  def Opam.all_packages
    system("opam remove -y `opam list --all --short \"coq-*\"`")
    `opam list --all --short --sort "coq-*"`.split(" ").map do |name|
      name = name.strip
      Opam.versions(name).map {|version| Package.new(name, version)}
    end.flatten.reverse
  end

  # Add a repository.
  def Opam.add_repository(repository)
    system("opam", "repo", "add", repository.to_s, Opam.repositories[repository])
  end
end