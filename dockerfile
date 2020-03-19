FROM ubuntu:18.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential \
apt-utils \
wget \
build-essential \
tar \
default-jre 
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3.6 \
python-dev \
python-distribute \
python3-pip

RUN pip3 install wheel \
setuptools \
numpy \
pandas \
scipy 
RUN pip3 install sklearn
RUN pip3 install biopython
RUN pip3 install openpyxl

# Install ViennaRNA
RUN wget -q https://www.tbi.univie.ac.at/RNA/download/ubuntu/ubuntu_18_04/python3-rna_2.4.14-1_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y ./python3-rna_2.4.14-1_amd64.deb
RUN rm python3-rna_2.4.14-1_amd64.deb

RUN mkdir mirna
WORKDIR mirna