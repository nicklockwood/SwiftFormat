# syntax=docker/dockerfile:1

# Base image and static SDK have to be updated together.
FROM --platform=$BUILDPLATFORM swift:6.3.2 AS builder
WORKDIR /workspace
RUN swift sdk install \
	https://download.swift.org/swift-6.3.2-release/static-sdk/swift-6.3.2-RELEASE/swift-6.3.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz \
	--checksum 3fd798bef6f4408f1ea5a6f94ce4d4052830c4326ab85ebc04f983f01b3da407

COPY . /workspace
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM \
	./Scripts/build-linux-release.sh && \
	cp /workspace/.build/release/swiftformat /workspace

# https://github.com/nicklockwood/SwiftFormat/issues/1930
FROM scratch AS runner
COPY --from=builder /workspace/swiftformat /usr/bin/swiftformat
ENTRYPOINT [ "/usr/bin/swiftformat" ]
CMD ["."]
