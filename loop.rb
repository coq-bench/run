# An infinite loop to run all the benches.

ocaml = ARGV[0]

repositories = ["released", "extra-dev"]
# repositories = ["released"]

# modes = {
#   clean: ["8.4.5", "8.4.6", "8.4.dev", "8.5.dev", "dev", "hott"],
#   tree: [] }

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
    "8.10.0"
  ].reverse,
  # "extra-dev" => ["8.4.dev", "8.5.dev", "dev"]
  "extra-dev" => []
}

while true do
  for repository in repositories do
    for coq in coqs[repository] do
      mode = :clean
      # Initialize OPAM.
      system("rm -Rf ~/.opam*")
      system("opam init -n")
      Process.waitall
      # Create an OCaml switch with the same version as the system, to have a fresh and official install.
      system("opam switch create ocaml-base-compiler.#{ocaml}")
      # Add the repositories.
      system("rm -Rf opam-coq-archive && git clone https://github.com/coq/opam-coq-archive.git")
      # We disable the core-dev repo to check that packages can be installed with at least one stable version of Coq.
      # system("opam repo add core-dev opam-coq-archive/core-dev")
      # Install Coq.
      Process.waitall
      if system("opam install -y coq.#{coq}") then
        # We remove back the `released` repository.
        system("opam repo remove released")
        # Run the bench.
        system("ruby #{mode}.rb #{repository} ../database/#{mode}")
        Process.waitall
        # Update the HTML.
        system("cd ../make-html-master/html && git pull")
        system("cd ../make-html-master && ruby make_html.rb ../database html")
        system("cd ../make-html-master && ruby push_to_gitter.rb ../database ../run/gitter-token coq/opam-bench-reports")
        system("cd ../make-html-master/html && git add .;
          git commit -m \"Coq #{coq}, repo #{repository}, mode #{mode}.\";
          git push")
      end
      Process.waitall
    end
  end
end
