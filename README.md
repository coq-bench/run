# Run
Run the benchmarks.

## Use
### With Docker
Clone the [database](https://github.com/coq-bench/database) in `../database` and run:

    docker build --tag=run .
    docker run -ti -v `pwd`/../database:/root/database run ruby run.rb stable
    docker run -ti -v `pwd`/../database:/root/database run ruby run.rb testing
    docker run -ti -v `pwd`/../database:/root/database run ruby run.rb unstable

You can know commit the files added to `../database`.