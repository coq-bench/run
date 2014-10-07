# coq-bench

A tool to bench the OPAM [repository](https://github.com/coq/opam-coq-repo) for Coq.

## Links
* [http://clarus.github.io/coq-bench/](http://clarus.github.io/coq-bench/): to consult the benchmarks
* [https://github.com/clarus/coq-bench-csv](https://github.com/clarus/coq-bench-csv): the raw CSV database of the benchmarks

## Build
The bench suite runs in an isolated environment using [Docker](https://www.docker.com/). Build the image and connect to it:

    docker build --tag=coq-bench .
    docker run -ti coq-bench

Inside the container, run the benchmarks and update the results in the `csv/` folder (will take time):

    make bench

Generate a new website from the `csv/` database into the `html/` folder:

    make website

To quickly consult the results, serve the `html/` folder on [http://localhost:8080/](http://localhost:8080/):

    make server
