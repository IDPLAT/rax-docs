FROM python:3.3.6

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

run wget https://install.goreleaser.com/github.com/ValeLint/vale.sh && \
    sh vale.sh -b /usr/local/bin v2.4.0 && \
    mkdir -p styles/Vocab && \
    git clone https://github.com/achatur/docs-vale.git styles/docs-vale && \
    git clone https://github.com/errata-ai/Google.git styles/Google && \
    git clone https://github.com/errata-ai/Microsoft.git styles/Microsoft
