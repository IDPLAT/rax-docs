FROM python:3.6.13

COPY requirements.txt requirements.txt

RUN mkdir /root/.ssh && \
  chmod 0600 /root/.ssh && \
  ln -s /ssh_config/id_rsa /root/.ssh/id_rsa && \
  ln -s /ssh_config/id_rsa.pub /root/.ssh/id_rsa.pub && \
  ln -s /ssh_config/known_hosts /root/.ssh/known_hosts

RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  enchant \
  libbz2-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  llvm \
  make \
  tk-dev \
  wget \
  xz-utils \
  zlib1g-dev

RUN pip install --upgrade pip\<21
RUN pip install -r requirements.txt

ARG VALE_VERSION=2.4.0

run wget https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz && \
    mkdir /usr/local/lib/vale-${VALE_VERSION} && \
    tar -xvzf vale_${VALE_VERSION}_Linux_64-bit.tar.gz -C /usr/local/lib/vale-${VALE_VERSION} && \
    ln -s /usr/local/lib/vale-${VALE_VERSION}/vale /usr/local/bin/vale && \
    mkdir -p styles/Vocab && \
    git clone https://github.com/achatur/docs-vale.git styles/docs-vale && \
    git clone https://github.com/errata-ai/Google.git styles/Google && \
    git clone https://github.com/errata-ai/Microsoft.git styles/Microsoft
