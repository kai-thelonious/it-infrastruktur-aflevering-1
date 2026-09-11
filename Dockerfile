FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY checker.sh .
RUN chmod +x checker.sh

CMD ["./checker.sh"]
