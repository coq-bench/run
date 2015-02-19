# Run a full list of benches in Docker containers.

jobs = 4
opams = ["1.2.0", "1.2.1-beta3"]
# opams = ["1.2.1-beta3"]
# opams = ["1.2.0"]
# ocamls = ["4.01.0", "4.02.1"]
ocamls = ["4.02.1"]
repositories = ["stable", "unstable"]
# repositories = ["stable"]
modes = {
  clean: ["8.4.5", "8.5.dev", "dev", "hott"],
  tree: ["8.5.dev", "dev"] }
# coqs = ["8.4pl4", "8.4.5", "8.4.dev", "8.5beta1", "8.5.dev", "dev", "hott"]
# coqs = ["8.4.5", "8.5.dev", "dev", "hott"]

for opam in opams do
  for ocaml in ocamls do
    for repository in repositories do
      for mode, coqs in modes do
       for coq in coqs do
          system("ruby", "make_dockerfile.rb", jobs.to_s, ocaml, opam, coq)
          system("docker build --tag=run . && docker run -ti -v `pwd`/../database:/home/bench/database run ruby #{mode}.rb #{repository} ../database/#{mode}")
        end
      end
    end
  end
end
