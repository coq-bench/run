# Handle interactions with OPAM.
require_relative 'package'

module Opam
  # Coq repositories.
  def Opam.repositories
    { stable: "https://github.com/clarus/opam-coq-repo.git", # For now, a smaller fork.
      testing: "https://github.com/coq/opam-coq-repo-testing.git",
      unstable: "https://github.com/coq/opam-coq-repo-unstable.git" }
  end

  # The list of versions for a package name.
  def Opam.versions(name)
    `opam info --field=available-version,available-versions #{name}`.split(":")[-1].split(",").map {|version| version.strip}
  end

  # The list of all Coq packages.
  def Opam.all_packages
    `opam list --unavailable --short --sort "coq-*"`.split(" ").map do |name|
      name = name.strip
      Opam.versions(name).map {|version| Package.new(name, version)}
    end.flatten
  end

  # Add a list of repositories.
  def Opam.add_repositories(*repositories)
    for repository in repositories do
      system("opam repo add #{repository} #{Opam.repositories[repository]}")
    end
  end

  # Remove a list of repositories.
  def Opam.remove_repositories(*repositories)
    for repository in repositories do
      system("opam repo remove #{repository}")
    end
  end

  # Uninstall a package.
  def Opam.uninstall(package)
    system("opam remove -y #{package.name}")
  end

  # Install the dependencies of a package.
  def Opam.install_dependencies(package)
    system("opam install -y --deps-only #{package}")
  end

  # Install a package.
  def Opam.install(package)
    system("opam install -y #{package}")
  end
end