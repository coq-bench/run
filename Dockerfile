FROM ubuntu
MAINTAINER Guillaume Claret

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gcc make git

# Opam
RUN apt-get install -y opam
RUN opam init
ENV OPAMJOBS 6

# Ruby
RUN apt-get install -y ruby

# The Coq repositories
RUN opam repo add coq https://github.com/coq/opam-coq-repo.git
RUN opam repo add coq-testing https://github.com/coq/opam-coq-repo-testing.git
RUN opam repo add coq-unstable https://github.com/coq/opam-coq-repo-unstable.git

# Initialize the bench folder
ADD . /root/run
WORKDIR /root/run
