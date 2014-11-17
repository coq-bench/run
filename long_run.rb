# Run a full list of benches in Docker containers.

jobs = 4
opam = "1.2.0"
ocamls = ["4.01.0", "4.02.1"]
# repositories = ["stable", "testing", "unstable"]
repositories = ["stable", "unstable"]
coqs = ["8.4pl4", "8.4.5", "8.4.dev", "dev"]

for ocaml in ocamls.shuffle do
  for repository in repositories.shuffle do
    for coq in coqs.shuffle do
      system("ruby", "make_dockerfile.rb", jobs.to_s, ocaml, opam, coq)
      system("docker build --tag=run . && docker run -ti -v `pwd`/../database:/home/bench/database run ruby run.rb #{repository}")
    end
  end
end
