# GameDirection Wine Runner build
#
# Two-stage build. Stage "builder" compiles Wine from source against an
# old, pinned glibc baseline so the resulting binary runs on newer distros
# too (glibc is forward-compatible, not backward-compatible). Stage
# "packager" copies only the built output into a clean, minimal tarball,
# keeping build-only packages out of the shipped artifact.
#
# BASE_IMAGE picks the glibc floor. debian:10 (buster, glibc 2.28) is the
# verified default: ubuntu:18.04's gcc-mingw-w64 is too old to build Wine
# 11.15's libs/symcrypt (VAES intrinsics need GCC 8+, 18.04 ships an older
# default). debian:10 is also EOL, its apt sources get repointed at
# archive.debian.org below.
ARG BASE_IMAGE=debian:10
ARG WINE_VERSION=11.15

FROM ${BASE_IMAGE} AS builder
ARG WINE_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# debian:10 (buster) is fully EOL, its repos moved to archive.debian.org.
# ubuntu:18.04's default sources still resolve on their own; this is a no-op
# there.
RUN if [ -f /etc/apt/sources.list ] && grep -q "buster" /etc/apt/sources.list; then \
        sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
        echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until; \
    fi

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        gcc-mingw-w64 \
        g++-mingw-w64 \
        flex \
        bison \
        quilt \
        gettext \
        freetype2-demos \
        pkg-config \
        libx11-dev \
        libx11-dev:i386 \
        libfreetype6-dev \
        libfreetype6-dev:i386 \
        libfontconfig1-dev \
        libfontconfig1-dev:i386 \
        libxext-dev \
        libxext-dev:i386 \
        libxcursor-dev \
        libxi-dev \
        libxrandr-dev \
        libxrender-dev \
        libxinerama-dev \
        libxxf86vm-dev \
        libgl1-mesa-dev \
        libgl1-mesa-dev:i386 \
        libpulse-dev \
        libdbus-1-dev \
        libgnutls28-dev \
        libunwind-dev \
        ca-certificates \
        curl \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN curl -L -o wine.tar.xz \
        "https://dl.winehq.org/wine/source/$(echo ${WINE_VERSION} | cut -d. -f1).x/wine-${WINE_VERSION}.tar.xz" && \
    tar xf wine.tar.xz && \
    mv wine-${WINE_VERSION} wine-src

# Build context is Guides/Wine/ so patch 2 (the existing, already-tested
# SDR white-level patch) can be referenced in place instead of duplicated.
COPY Docker/Runner/patches/0001-wintypes-roresolve-affinity.patch /build/patches/
COPY Docker/Runner/patches/0003-d2d1-bezier-recursion-cap.patch /build/patches/
COPY wine-11.15-sdr-white-level.patch /build/patches/0002-sdr-white-level.patch

RUN cd wine-src && \
    for p in /build/patches/*.patch; do \
        echo "Applying $p" && patch -p1 < "$p"; \
    done

RUN mkdir -p /build/wine-build64 && cd /build/wine-build64 && \
    ../wine-src/configure --enable-win64 --without-opencl --without-vulkan \
        --disable-tests && \
    make -j"$(nproc)" && \
    make install DESTDIR=/build/out

# make install produces the standard relocatable Wine layout
# (usr/local/{bin,lib/wine,share/wine}). Wine finds its own lib/share dirs
# at runtime relative to the wine binary's own location, so flattening the
# usr/local prefix away and shipping bin/, lib/, share/ at the top level of
# the tarball keeps it portable to any extraction path.
FROM scratch AS packager
COPY --from=builder /build/out/usr/local/bin /gamedirection-wine/bin
COPY --from=builder /build/out/usr/local/lib /gamedirection-wine/lib
COPY --from=builder /build/out/usr/local/share/wine /gamedirection-wine/share/wine
COPY --from=builder /build/wine-src/LICENSE /gamedirection-wine/LICENSE
# docker create requires a CMD even though this image is never run directly,
# only used to extract /gamedirection-wine via docker cp.
CMD ["/gamedirection-wine/bin/wine"]
