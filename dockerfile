FROM ubuntu:18.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential \
apt-utils \
build-essential \
tar \
default-jre \
libopenmpi-dev \
openmpi-bin \
ghostscript \
libgs-dev \
libgd-dev \
libexpat1-dev \
zlib1g-dev \
libxml2-dev \
autoconf automake libtool \
libhtml-template-compiled-perl \
libxml-opml-simplegen-perl \
libxml-libxml-debugging-perl 
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
ADD https://www.tbi.univie.ac.at/RNA/download/ubuntu/ubuntu_18_04/python3-rna_2.4.14-1_amd64.deb .
RUN DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y ./python3-rna_2.4.14-1_amd64.deb && rm python3-rna_2.4.14-1_amd64.deb

#install MEME suite
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Log::Log4perl'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Math::CDF'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install CGI'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install HTML::PullParser'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install HTML::Template'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Simple'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Parser::Expat'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::LibXML'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::LibXML::Simple'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Compile'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Compile::SOAP11'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Compile::WSDL11'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install XML::Compile::Transport::SOAPHTTP'

RUN mkdir /opt/meme
ADD http://meme-suite.org/meme-software/5.1.0/meme-5.1.0.tar.gz /opt/meme
WORKDIR /opt/meme/
RUN tar zxvf meme-5.1.0.tar.gz && rm -fv meme-5.1.0.tar.gz
RUN cd /opt/meme/meme-5.1.0 && \
	./configure --prefix=/opt  --enable-build-libxml2 --enable-build-libxslt  --with-url=http://meme-suite.org && \ 
	make && \
	make install && \
        rm -rfv /opt/meme
ENV PATH="/opt/bin:${PATH}"

RUN mkdir mirna
WORKDIR mirna