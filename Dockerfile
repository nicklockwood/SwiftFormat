# syntax=docker/dockerfile:1

# Base image and static SDK have to be updated together.
FROM --platform=$BUILDPLATFORM swift:6.0.2 AS builder
WORKDIR /workspace
RUN swift sdk install \
	https://download.swift.org/swift-6.0.2-release/static-sdk/swift-6.0.2-RELEASE/swift-6.0.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
	--checksum aa5515476a403797223fc2aad4ca0c3bf83995d5427fb297cab1d93c68cee075

COPY . /workspace
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM \
	./Scripts/build-linux-release.sh && \
	cp /workspace/.build/release/swiftformat /workspace

# https://github.com/nicklockwood/SwiftFormat/issues/1930
FROM busybox:stable AS runner
COPY --from=builder /workspace/swiftformat /usr/bin/swiftformat
ENTRYPOINT [ "/usr/bin/swiftformat" ]
CMD ["."]
