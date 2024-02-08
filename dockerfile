FROM golang:1.22.0 AS builder

WORKDIR /src

COPY src/go.mod ./
RUN go mod download

COPY src .

RUN CGO_ENABLED=0 GOOS=linux go build -o /app -a -ldflags '-extldflags "-static"' .

FROM alpine:3.19.1

COPY --from=builder /app /app

ENV HORIZON_SALT=""
USER nobody

EXPOSE 80
ENTRYPOINT ["/bin/sh", "-c", "/app -salt=${HORIZON_SALT}"]
