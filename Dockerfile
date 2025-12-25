FROM alpine:latest

# Install dependencies
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk --no-cache add wget tar sudo certbot bash python3 py3-pip && \
    apk --no-cache add --virtual build-dependencies gcc musl-dev python3-dev libffi-dev openssl-dev make tzdata

# Install aliyun-cli
RUN wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz && \
    tar xzvf aliyun-cli-linux-latest-amd64.tgz && \
    mv aliyun /usr/local/bin && \
    rm aliyun-cli-linux-latest-amd64.tgz

# Copy and install certbot-dns-aliyun plugin
COPY alidns.sh /usr/local/bin/alidns
RUN chmod +x /usr/local/bin/alidns

# Create virtual environment for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies in virtual environment
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    pip install --upgrade pip && \
    pip install aliyun-python-sdk-core aliyun-python-sdk-alidns

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY refresh.sh /usr/local/bin/refresh.sh
RUN chmod +x /usr/local/bin/refresh.sh

COPY reload.sh /usr/local/bin/reload.sh
RUN chmod +x /usr/local/bin/reload.sh

RUN cp /usr/share/zoneinfo/Asia/Shanghai Asia_Shanghai && \
    apk del build-dependencies && \
    mkdir -p /usr/share/zoneinfo/Asia && \
    mv Asia_Shanghai /usr/share/zoneinfo/Asia/Shanghai

# Set environment variables (to be provided during runtime)
ENV REGION=""
ENV ACCESS_KEY_ID=""
ENV ACCESS_KEY_SECRET=""
ENV DOMAIN=""
ENV EMAIL=""
ENV CRON_SCHEDULE="0 0 * * *"
ENV DEPLOY_OPER=""
ENV OSS_BUCKET=""

# Setup cron job for certbot renew
RUN echo "$CRON_SCHEDULE /usr/local/bin/refresh.sh" > /etc/crontabs/root

# Create directory for certificates
RUN mkdir -p /etc/letsencrypt/certs

# Make sure cron is running
RUN touch /var/log/cron.log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

