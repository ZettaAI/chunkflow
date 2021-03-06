#FROM tensorflow/tensorflow:1.14.0-gpu-py3
FROM pytorch/pytorch:1.8.0-cuda11.1-cudnn8-runtime
ARG CHUNKFLOW_USER=chunkflow
ENV CHUNKFLOW_USER ${CHUNKFLOW_USER}


ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV CHUNKFLOW_HOME /workspace/chunkflow

WORKDIR ${CHUNKFLOW_HOME}

RUN savedAptMark="$(apt-mark showmanual)" \
    && apt-get update && apt-get install -y -qq --no-install-recommends \
        apt-utils \
        wget \
        git \
        build-essential \
        python3-dev \
        python3-distutils \
        curl \
        ca-certificates \
        gnupg-agent \
        gnupg \
        dirmngr \
    # test whether pip is working 
    # there is an issue of pip:
    # https://github.com/laradock/laradock/issues/1496
    # we need this hash to solve this issue
    # && ln -sf /usr/bin/pip3 /usr/bin/pip \
    # this do not work due to an issue in pip3
    # https://github.com/pypa/pip/issues/5240
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y \
    && pip install -U --no-cache-dir pip \
    && pip install -U --no-cache-dir cloud-volume \
    && git clone https://github.com/seung-lab/DeepEM \
    && git clone https://github.com/seung-lab/dataprovider3 \
    && git clone https://github.com/seung-lab/pytorch-emvision \
    && echo "[GoogleCompute]\nservice_account = default" > /etc/boto.cfg \
    && apt-mark auto '.*' > /dev/null \
    && apt-mark manual google-cloud-sdk python3-setuptools python3-distutils \
    && apt-mark manual $savedAptMark \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf \
        /root/.cache/pip \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY . /workspace/chunkflow

RUN pwd && ls \
    && pip install --no-cache-dir -r requirements.txt --no-cache-dir \
    && pip install --no-cache-dir -r tests/requirements.txt --no-cache-dir \
    # install the commandline chunkflow
    && pip install --no-cache-dir -e . \
    # cleanup system libraries 
    # the test will not pass due to missing of credentials.
    # && pytest tests \
    && chunkflow

RUN groupadd -r ${CHUNKFLOW_USER} \
      && useradd -r -d ${CHUNKFLOW_HOME} -g ${CHUNKFLOW_USER} -s /bin/bash ${CHUNKFLOW_USER} \
      && chown -R ${CHUNKFLOW_USER}: ${CHUNKFLOW_HOME} \
      # && usermod -aG docker ${CHUNKFLOW_USER} \
      # unfortunately this is required to update the container docker gid to match the
      # host's gid, we remove this permission from entrypoint-dood.sh script
      && echo "${CHUNKFLOW_USER} ALL=NOPASSWD: ALL" >> /etc/sudoers

LABEL workspace_path=${CHUNKFLOW_HOME} \
      mount_path="/run/secrets" \
      maintainer="Ran Lu" \
      email="ranl@princeton.edu"


USER ${CHUNKFLOW_USER}
