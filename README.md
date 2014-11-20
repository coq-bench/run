# Run
Run the benchmarks.

## Use
### With Docker
Clone the [database](https://github.com/coq-bench/database) in `../database`. Generate a `Dockerfile` for a specific configuration:

    ruby make_dockerfile.rb 4 4.02.1 1.2.0 8.4.5

Build the Docker image:

    docker build --tag=run .

Run the image for each repository:

    docker run -ti -v `pwd`/../database:/root/database run ruby run.rb stable
    docker run -ti -v `pwd`/../database:/root/database run ruby run.rb unstable

You can now commit the files added to `../database`.
