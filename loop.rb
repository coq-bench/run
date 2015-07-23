# An infinite loop to run all the benches.

repositories = ["released", "extra-dev"]
#repositories = ["released"]

# modes = {
#   clean: ["8.4.5", "8.4.6", "8.4.dev", "8.5.dev", "dev", "hott"],
#   tree: [] }

coqs = {
  "released" => ["8.3.dev", "8.4.6~camlp4", "8.4.6", "8.4.dev", "8.5~beta2", "8.5.0~beta2", "8.5.dev", "dev"],
  "extra-dev" => ["8.4.dev", "8.5.dev", "dev"]
}

while true do
  for repository in repositories do
    for coq in coqs[repository] do
      mode = :clean
      # Initialize OPAM.
      system("rm -Rf ~/.opam*")
      system("opam init -n")
      # Install Coq.
      system("opam repo add coq-core-dev https://coq.inria.fr/opam/core-dev")
      if system("opam install -y coq.#{coq}") then
        # Add the repositories.
        system("rm -Rf opam-coq-archive && git clone https://github.com/coq/opam-coq-archive.git")
        # Run the bench.
        system("ruby #{mode}.rb #{repository} ../database/#{mode}")
        # Update the HTML.
        system("cd ../make-html-master && ruby make_html.rb ../database html")
        system("cd ../make-html-master/html && git pull && git add .;
          git commit -m \"Coq #{coq}, repo #{repository}, mode #{mode}.\";
          git push")
      end
      # Clean the zombies.
      Process.waitall
    end
  end
end
