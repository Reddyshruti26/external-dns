FROM golang:1.23.5 AS builder
ARG ARCH

WORKDIR /sigs.k8s.io/external-dns

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN make build
FROM alpine:3.18

RUN apk add --no-cache ca-certificates
COPY --from=builder /sigs.k8s.io/external-dns/build/external-dns /bin/external-dns

# Run as UID for nobody since k8s pod securityContext runAsNonRoot can't resolve the user ID:
# https://github.com/kubernetes/kubernetes/issues/40958
USER nobody

ENTRYPOINT ["/bin/external-dns"]