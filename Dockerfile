# syntax=docker/dockerfile:1

# Swift official image with arm64 support
# https://hub.docker.com/r/arm64v8/swift/
ARG SWIFT_IMAGE=swift:focal

FROM $SWIFT_IMAGE AS builder
COPY . /workspace
WORKDIR /workspace
RUN swift build -c release && mv `swift build -c release --show-bin-path`/swiftformat /workspace

FROM $SWIFT_IMAGE-slim AS runner
COPY --from=builder /workspace/swiftformat /usr/bin
ENTRYPOINT [ "swiftformat" ]
CMD ["."]
