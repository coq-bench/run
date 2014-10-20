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

RUN opam install -y coq.8.3

# Initialize the bench folder
ADD . /root/run
WORKDIR /root/run
