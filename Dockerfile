# syntax=docker/dockerfile:1

# Base image and static SDK have to be updated together.
FROM --platform=$BUILDPLATFORM swift:6.0.3 AS builder

# Create a non-root user
RUN adduser --disabled-password --gecos "" swiftformat

# Switch to non-root user
USER swiftformat
WORKDIR /workspace
RUN swift sdk install \
	https://download.swift.org/swift-6.0.3-release/static-sdk/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
	--checksum 67f765e0030e661a7450f7e4877cfe008db4f57f177d5a08a6e26fd661cdd0bd

COPY . /workspace
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM \
	./Scripts/build-linux-release.sh && \
	cp /workspace/.build/release/swiftformat /workspace

# https://github.com/nicklockwood/SwiftFormat/issues/1930
FROM scratch AS runner

# Create a non-root user
RUN adduser --disabled-password --gecos "" swiftformat

# Switch to non-root user
USER swiftformat
COPY --from=builder /workspace/swiftformat /usr/bin/swiftformat
ENTRYPOINT [ "/usr/bin/swiftformat" ]
CMD ["."]
