FROM ubuntu
MAINTAINER Guillaume Claret

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gcc make git
RUN apt-get install -y libgtksourceview2.0-dev m4
RUN apt-get install -y curl ocaml
RUN apt-get install -y ruby

# Opam 1.2.0-rc4
WORKDIR /root
RUN curl -L https://github.com/ocaml/opam/archive/1.2.0-rc4.tar.gz |tar -xz
WORKDIR opam-1.2.0-rc4
RUN ./configure
RUN make lib-ext
RUN make
RUN make install
RUN opam init
ENV OPAMJOBS 6

# The Coq repositories
RUN opam repo add coq https://github.com/coq/opam-coq-repo.git
RUN opam repo add coq-testing https://github.com/coq/opam-coq-repo-testing.git
RUN opam repo add coq-unstable https://github.com/coq/opam-coq-repo-unstable.git

# Initialize the bench folder
ADD . /root/run
WORKDIR /root/run
