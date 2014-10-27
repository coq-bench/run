# Handle interactions with OPAM.
require_relative 'package'

module Opam
  # The list of all Coq packages in the given repositories.
  def Opam.all_packages(repositories)
    repositories.map do |repository|
      Dir.glob("../#{repository}/packages/*/*").map do |path|
        File.basename(path).split(".", 2)
      end
    end.flatten(1).sort
  end

  # Add a repository.
  def Opam.add_repository(repository)
    system("opam", "repo", "add", "--kind=git", repository, "../#{repository}")
  end
end