# An infinite loop to run all the benches.

repositories = ["released", "extra-dev"]
# repositories = ["released"]

# modes = {
#   clean: ["8.4.5", "8.4.6", "8.4.dev", "8.5.dev", "dev", "hott"],
#   tree: [] }

coqs = {
  "released" => [
    "8.5.3",
    "8.5.dev",
    "8.6.1",
    "8.6.2",
    "8.6.dev",
    "8.7.0",
    "8.7.1",
    "8.7.2",
    "8.7.dev",
    "dev"
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
      # Add the repositories.
      system("rm -Rf opam-coq-archive && git clone https://github.com/coq/opam-coq-archive.git")
      system("opam repo add core-dev opam-coq-archive/core-dev")
      # Install Coq.
      Process.waitall
      if system("opam install -y coq.#{coq}") then
        # We remove back the `released` repository.
        system("opam repo remove released")
        # Run the bench.
        system("ruby #{mode}.rb #{repository} ../database/#{mode}")
        Process.waitall
        # Update the HTML.
        system("cd ../make-html-master && ruby make_html.rb ../database html")
        system("cd ../make-html-master/html && git pull && git add .;
          git commit -m \"Coq #{coq}, repo #{repository}, mode #{mode}.\";
          git push")
      end
      Process.waitall
    end
  end
end
