# An infinite loop to run all the benches.

repositories = ["stable", "unstable"]
# repositories = ["stable"]
modes = {
  clean: ["8.4.6", "8.4.dev", "8.5.dev", "dev", "hott"],
  tree: [] }

while true do
  for repository in repositories do
    for mode, coqs in modes do
     for coq in coqs do
        # Initialize OPAM.
        system("rm -Rf ~/.opam*")
        system("opam init -n")
        # Install Coq.
        system("opam repo add coqs https://github.com/coq/repo-coqs.git")
        if system("opam install -y coq.#{coq}") then
          # Add the repositories.
          system("rm -Rf ../stable && git clone https://github.com/coq/repo-stable.git ../stable")
          system("rm -Rf ../unstable && git clone https://github.com/coq/repo-unstable.git ../unstable")
          # Run the bench.
          system("ruby #{mode}.rb #{repository} ../database/#{mode}")
          # Update the HTML.
          system("cd ../make-html-master && ruby make_html.rb ../database html")
          system("cd ../make-html-master/html && git pull && git add .;
            git commit -m \"Coq #{coq}, repo #{repository}, mode #{mode}.\";
            git push")
        end
      end
    end
  end
end
