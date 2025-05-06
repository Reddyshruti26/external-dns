#FROM golang:1.23.5 AS builder
#ARG ARCH

#WORKDIR /sigs.k8s.io/external-dns

#COPY go.mod .
#COPY go.sum .
#RUN go mod download

#COPY . .
#RUN make build
#FROM alpine:3.18

#RUN apk add --no-cache ca-certificates
#COPY --from=builder /sigs.k8s.io/external-dns/build/external-dns /bin/external-dns

# Run as UID for nobody since k8s pod securityContext runAsNonRoot can't resolve the user ID:
# https://github.com/kubernetes/kubernetes/issues/40958
#USER nobody

#ENTRYPOINT ["/bin/external-dns"]
FROM golang:1.23.5 AS builder
ARG ARCH

WORKDIR /sigs.k8s.io/external-dns

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY . .

# Explicitly disable CGO to create a static binary for Alpine
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH:-amd64} go build -o build/external-dns -ldflags="-w -s -X sigs.k8s.io/external-dns/pkg/apis/externaldns.Version=v0.16.1" .

# Use minimal runtime image
FROM alpine:3.18

RUN apk add --no-cache ca-certificates

# Copy static binary #ENV AZURE_SDK_MAX_RETRIES=-1
COPY --from=builder /sigs.k8s.io/external-dns/build/external-dns /bin/external-dns

# Run as non-root user
USER nobody

ENTRYPOINT ["/bin/external-dns"]
