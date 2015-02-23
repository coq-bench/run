# Run
Run the benchmarks.

## Instructions
There must be a file `id_rsa` in the current folder, giving a private key to access the [coq-bench.github.io](https://github.com/coq-bench/coq-bench.github.io) repository. Create a folder to save the CSV outputs of the bench:

    mkdir ../database

Then run as root:

    ruby run.rb 4 4.02.1 1.2.0 ../database # 4 CPUs, OCaml 4.02.1, OPAM 1.2.0

It will launch a Dockerfile, install all the dependencies and run the benches on all Coq versions in an infinite loop. The results will be saved in the database and pushed online on [coq-bench.github.io](https://github.com/coq-bench/coq-bench.github.io).
