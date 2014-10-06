FROM ubuntu
MAINTAINER Guillaume Claret

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gcc make git

# Opam
RUN apt-get install -y opam
RUN opam init

# Compile with -j4
ENV OPAMJOBS 4

# Coq
RUN opam install -y coq

# Ruby
RUN apt-get install -y ruby

# The Coq repository
WORKDIR /root
RUN git clone https://github.com/coq/opam-coq-repo.git
RUN opam repo add coq opam-coq-repo

# Run the bench
RUN mkdir /root/coq-bench
WORKDIR /root/coq-bench

# RUN ruby generate_csv.rb
# RUN ruby generate_html.rb

CMD ruby -run -e httpd . -p 80