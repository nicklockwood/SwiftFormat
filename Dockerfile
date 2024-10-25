# syntax=docker/dockerfile:1

# Base image and static SDK have to be updated together.
FROM --platform=$BUILDPLATFORM swift:6.0.1 AS builder
WORKDIR /workspace
RUN swift sdk install \
	https://download.swift.org/swift-6.0.1-release/static-sdk/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
	--checksum d4f46ba40e11e697387468e18987ee622908bc350310d8af54eb5e17c2ff5481

COPY . /workspace
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM \
	./Scripts/build-linux-release.sh && \
	cp /workspace/.build/release/swiftformat /workspace
RUN strip /workspace/swiftformat

FROM scratch AS runner
COPY --from=builder /workspace/swiftformat /usr/bin/swiftformat
ENTRYPOINT [ "/usr/bin/swiftformat" ]
CMD ["."]
