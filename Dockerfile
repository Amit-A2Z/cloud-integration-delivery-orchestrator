# Multi-stage Dockerfile for cpi-delivery
#
# Build context must be the backend directory (mmt-devops-cpi-delivery/)
# with web/dist/ already populated with frontend build output.
#
# Usage (from cpi-delivery-product/docker/):
#   make build
#
# Or manually (from this directory):
#   docker build -f Dockerfile -t cpi-delivery ../../mmt-devops-cpi-delivery

# === Build stage: compile Go binary with embedded frontend ===
FROM --platform=$BUILDPLATFORM golang:1.25-alpine3.24 AS builder

# Set by BuildKit from --platform (or --arch / --os). No defaults: a default here
# wins over the value Apple container's builder passes, and pins every build to it.
ARG TARGETOS
ARG TARGETARCH

ENV GOPROXY=https://proxy.golang.org,direct

WORKDIR /app
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /cpi-delivery .

# === Runtime stage ===
FROM alpine:3.24

RUN apk --no-cache add ca-certificates tzdata
COPY --from=builder /cpi-delivery /usr/local/bin/cpi-delivery

EXPOSE 8080
ENTRYPOINT ["cpi-delivery"]
