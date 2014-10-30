FROM ubuntu:14.10
MAINTAINER Guillaume Claret

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gcc make git
RUN apt-get install -y m4
RUN apt-get install -y curl ocaml
RUN apt-get install -y g++ ruby

# # OCaml 4.02
# WORKDIR /root
# RUN apt-get install -y curl
# RUN curl -L https://github.com/ocaml/ocaml/archive/4.02.0.tar.gz |tar -xz
# WORKDIR /root/ocaml-4.02.0
# RUN ./configure
# RUN make world.opt
# RUN make install

# # Camlp4 4.02
# WORKDIR /root
# RUN curl -L https://github.com/ocaml/camlp4/archive/4.02.0+1.tar.gz |tar -xz
# WORKDIR /root/camlp4-4.02.0-1
# RUN ./configure
# RUN make all
# RUN make install

# OPAM from Ubuntu
# RUN apt-get install -y opam

# OPAM from the sources
WORKDIR /root
RUN curl -L https://github.com/ocaml/opam/archive/1.2.0.tar.gz |tar -xz
WORKDIR opam-1.2.0
RUN ./configure
RUN make lib-ext
RUN make
RUN make install

# Initialize OPAM
RUN opam init
ENV OPAMJOBS 4

# OCaml 4.02.0
# RUN opam switch 4.02.0

# Coq
RUN opam repo add coqs https://github.com/coq/repo-coqs.git
RUN opam install -y coq.8.4.5

# Repositories
WORKDIR /root
RUN git clone https://github.com/coq/repo-stable.git stable
RUN git clone https://github.com/coq/repo-testing.git testing
RUN git clone https://github.com/coq/repo-unstable.git unstable

# Initialize the bench folder
ADD . /root/run
WORKDIR /root/run
RUN ln -s ~/.opam ./
