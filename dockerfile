FROM continuumio/miniconda3:4.9.2

SHELL ["/bin/bash", "--login", "-c"]

RUN mkdir -p /usr/share/man/man1/
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends -y sudo default-jre build-essential zlib1g-dev libxml2-dev libxml-parser-perl 

ADD ./perl-rna_2.4.17-1_amd64.deb ./
RUN DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y ./perl-rna_2.4.17-1_amd64.deb
RUN rm ./perl-rna_2.4.17-1_amd64.deb


# RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential \
# apt-utils \
# build-essential \
# tar \
# default-jre \
# libopenmpi-dev \
# openmpi-bin \
# ghostscript \
# libgs-dev \
# libgd-dev \
# libexpat1-dev \
# zlib1g-dev \
# libxml2-dev \
# autoconf automake libtool \
# libhtml-template-compiled-perl \
# libxml-opml-simplegen-perl \
# libxml-libxml-debugging-perl \
# openssh-server \
# sudo \
# wget


# RUN pip3 install wheel \
# setuptools \
# scipy 

# RUN pip3 install openpyxl xlrd

RUN mkdir /opt/meme
ADD http://meme-suite.org/meme-software/5.1.0/meme-5.1.0.tar.gz /opt/meme
WORKDIR /opt/meme/
RUN tar zxf meme-5.1.0.tar.gz && rm -f meme-5.1.0.tar.gz
RUN cd /opt/meme/meme-5.1.0 && \
	./configure --prefix=/opt  --enable-build-libxml2 --enable-build-libxslt  --with-url=http://meme-suite.org && \ 
	make -s && \
	make -s install && \
        rm -rf /opt/meme
ENV PATH="/opt/bin:/opt/libexec/meme-5.1.0:${PATH}"
ADD http://meme-suite.org/meme-software/Databases/motifs/motif_databases.12.19.tgz /opt/share/meme-5.1.0/db
WORKDIR /opt/share/meme-5.1.0/db
RUN tar xzf motif_databases.12.19.tgz && rm -f motif_databases.12.19.tgz

ARG UNAME=testuser
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

ADD ./environment.yml ./
RUN conda env create -f environment.yml
RUN rm ./environment.yml

USER $UNAME

RUN conda init bash
RUN echo "conda activate mirnaenv" >> ~/.bashrc

WORKDIR /mirna

# #install cmscan
# RUN mkdir /opt/cmscan
# ADD http://eddylab.org/infernal/infernal-1.1.3.tar.gz /opt/cmscan
# WORKDIR /opt/cmscan
# RUN tar xf infernal-1.1.3.tar.gz && rm -fv infernal-1.1.3.tar.gz
# RUN cd infernal-1.1.3 && ./configure && make && make install && rm -rf /opt/cmscan/