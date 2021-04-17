# An infinite loop to run all the benches.

ocaml = ARGV[0]

repositories = ["released", "extra-dev"]

coqs = {
  "released" => [
    "8.3",
    "8.4pl1",
    "8.4pl2",
    "8.4pl4",
    "8.4.5",
    "8.4.6~camlp4",
    "8.4.6",
    "8.5.0~camlp4",
    "8.5.0",
    "8.5.1",
    "8.5.2~camlp4",
    "8.5.2",
    "8.5.3",
    "8.6",
    "8.6.1",
    "8.7.0",
    "8.7.1",
    "8.7.1+1",
    "8.7.1+2",
    "8.7.2",
    "8.8.0",
    "8.8.1",
    "8.8.2",
    "8.9.0",
    "8.9.1",
    "8.10.0",
    "8.10.1",
    "8.10.2",
    "8.11.0",
    "8.11.1",
    "8.11.2",
    "8.12.0",
    "8.12.1",
    "8.12.2",
    "8.13.0",
    "8.13.1",
    "8.13.2",
    # future versions
    "8.14.0",
    "8.14.1",
    "8.14.2",
    "8.15.0",
    "8.15.1",
    "8.15.2",
    "8.16.0",
    "8.16.1",
    "8.16.2"
  ],
  "extra-dev" => [
    # "8.0.dev",
    # "8.1.dev",
    # "8.2.dev",
    # "8.3.dev",
    # "8.4.dev",
    # "8.5.dev",
    # "8.6.dev",
    # "8.7.dev",
    # "8.8.dev",
    # "8.9.dev",
    # "8.10.0",
    # "8.10.dev",
    # "8.11.dev",
    "dev"
  ]
}

configurations = []
for repository in repositories do
  for coq in coqs[repository] do
    configurations << {coq: coq, repository: repository}
  end
end
configurations.shuffle!

while true do
  for configuration in configurations do
    mode = :clean
    coq = configuration[:coq]
    repository = configuration[:repository]
    # Initialize OPAM.
    system("rm -Rf ~/.opam*")
    system("opam init -n")
    Process.waitall
    # Create an OCaml switch with the same version as the system, to have a fresh and official install.
    system("opam switch create ocaml-base-compiler.#{ocaml}")
    # Add the repositories.
    system("rm -Rf opam-coq-archive && git clone https://github.com/coq/opam-coq-archive.git")
    # We do not enable the core-dev repository for stable packages to check that packages can be installed
    # with at least one stable version of Coq.
    if repository != "released" then
      system("opam repo add core-dev opam-coq-archive/core-dev")
    end
    # Install Coq.
    Process.waitall
    if system("opam install -y coq.#{coq}") then
      # We remove back the `released` repository.
      system("opam repo remove released")
      # Run the bench.
      system("ruby #{mode}.rb #{repository} ../database/#{mode}")
      Process.waitall
      # Update the HTML.
      system("cd ../make-html && git pull")
      system("cd ../make-html/html && git pull")
      system("cd ../make-html && ruby make_html.rb ../database html")
      system("cd ../make-html/html && git add .;
        git commit -m \"Coq #{coq}, repo #{repository}, mode #{mode}.\";
        git push")
    end
    Process.waitall
  end
end
