FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y --no-install-recommends git
RUN apt-get install -y --no-install-recommends build-essential
RUN apt-get install -y --no-install-recommends ca-certificates

ARG USER
ARG GROUP

RUN groupadd ${USER} \
  && useradd ${USER} -g ${GROUP} -m

USER ${USER}

WORKDIR /tmp
RUN git clone https://github.com/vlang/v

WORKDIR /tmp/v
# v0.3.3
RUN git switch weekly.2023.14 -c work
RUN make
RUN rm -rf .git

# --------------------------------

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libatomic1 \
    ruby \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG USER
ARG GROUP

RUN groupadd ${USER} \
  && useradd ${USER} -g ${GROUP} -m

USER ${USER}

WORKDIR /home/${USER}

COPY --from=builder /tmp/v /home/${USER}/v

WORKDIR /home/${USER}/work

ENV PATH=/home/${USER}/v:${PATH}
ENV IN_CONTAINER=1
