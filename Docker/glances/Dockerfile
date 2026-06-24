FROM alpine:3.21

RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    python3-dev \
    musl-dev \
    linux-headers \
    && pip3 install --no-cache-dir --break-system-packages glances[web] docker \
    && apk del gcc python3-dev musl-dev linux-headers

EXPOSE 61208

CMD ["glances", "-w", "-B", "0.0.0.0"]
