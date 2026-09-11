FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY feeder.sh .
RUN chmod +x feeder.sh

CMD ["./feeder.sh"]
