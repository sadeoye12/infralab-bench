FROM --platform=linux/amd64 python:3.13-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y curl ca-certificates gnupg postgresql postgresql-client hdf5-tools jq && rm -rf /var/lib/apt/lists/*

RUN systemctl disable postgresql || true

RUN pip install --break-system-packages h5py pyyaml

WORKDIR /app

RUN mkdir -p /app/sweep /etc /opt /var/lib /data /opt/task

COPY check_cache.sh /app/sweep/check_cache.sh
COPY search.py /app/sweep/search.py
COPY build_cache.py /app/sweep/build_cache.py
COPY run.sh /app/sweep/run.sh
COPY sweep.yaml /etc/sweep.yaml
COPY fallback.yaml /opt/fallback.yaml
COPY cache_meta.json /var/lib/cache_meta.json
COPY prestart_setup.sh /opt/task/prestart_setup.sh

RUN chmod +x /app/sweep/*.sh /opt/task/prestart_setup.sh
RUN /opt/task/prestart_setup.sh && rm -f /opt/task/prestart_setup.sh /tmp/insert.sql

# Build the initial broken state
RUN python3 /app/sweep/build_cache.py --radius 3
CMD su - postgres -c "pg_ctlcluster 15 main start" && tail -f /dev/null
