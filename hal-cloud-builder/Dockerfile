FROM ubuntu as intermediate

ENV TERRAFORM_VERSION=0.11.7

RUN  apt-get update \
     && apt-get -y install unzip curl

RUN curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin \
    && chmod +x /usr/local/bin/terraform

FROM gcr.io/cloud-builders/gcloud

ENV TERM=xterm-256color
ENV HAL_USER=hal
ENV HOME=/root

RUN useradd -m $HAL_USER  

RUN curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh \
    && chmod +x InstallHalyard.sh \
    && bash InstallHalyard.sh  -y \
    && mkdir ${HOME}/.hal

COPY --from=intermediate /usr/local/bin/terraform /usr/local/bin/terraform

ENTRYPOINT [ "/usr/local/bin/hal" ]
