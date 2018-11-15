FROM ubuntu:latest

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y tzdata locales

RUN apt-get install -y \
    less \
    man \
    ssh \
    python \
    python-pip \
    python-virtualenv \
    vim \
    vim-nox \
    zip \
    parallel \
    openssl

RUN pip install awscli

RUN adduser aws
WORKDIR /home/aws
USER aws

COPY --chown=aws glacierupload glacierabort treehash  ./
COPY --chown=aws test/glacierupload/test_upload.sh  ./
COPY --chown=aws test/glacierupload/config .aws/config
COPY --chown=aws test/glacierupload/credentials .aws/credentials

RUN chmod +x glacierupload
RUN chmod +x glacierabort
RUN chmod +x treehash
RUN chmod +x test_upload.sh

CMD ./test_upload.sh
