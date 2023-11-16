#!/bin/bash

CURRENT_DIR=$(pwd)
GCC_VERSION="13.2.0"
# GCC_GIT="git://gcc.gnu.org/git/gcc.git"
GCC_GIT="https://git.m.ac/mirrors/gcc.git"
GCC_SRC="${CURRENT_DIR}/../src"
BUILD_DIR="build"

# Clone GCC
echo "===> Cloning GCC..."
git clone -b "releases/gcc-$GCC_VERSION" --depth 1 "${GCC_GIT}" "${GCC_SRC}"

# Apply patches
echo "===> Applying patches..."
cd ${GCC_SRC}
patch -p1 < ../patches/gcc-$GCC_VERSION.patch
cd ${CURRENT_DIR}

# Configure GCC
echo "===> Configuring GCC..."
cd ${CURRENT_DIR}/${BUILD_DIR}
${GCC_SRC}/configure -v \
  --enable-languages=c,c++ \
  --prefix=/usr \
  --build=x86_64-linux-gnu \
  --host=x86_64-linux-gnu \
  --target=x86_64-linux-gnu \
  --with-pkgversion="s2oj-gcc-$GCC_VERSION~1baoshuo1"

# Build GCC
echo "===> Building GCC..."
make -j$(nproc)

# Make .deb package
echo "===> Making .deb package \"s2oj-gcc-$GCC_VERSION~1baoshuo1.deb\" ..."
make -j$(nproc) DESTDIR=${CURRENT_DIR}/deb install
cd ${CURRENT_DIR}/deb
mkdir -p DEBIAN
cat << EOF > DEBIAN/control
Package: s2oj-gcc
Version: $GCC_VERSION~1baoshuo1
Section: base
Priority: optional
Architecture: amd64
Maintainer: Baoshuo <i@baoshuo.ren>
Description: GCC $GCC_VERSION for S2OJ
EOF
cd ${CURRENT_DIR}
dpkg-deb --build deb s2oj-gcc-$GCC_VERSION~1baoshuo1.deb

# Upload package to Gitea
echo "===> Uploading package to Gitea..."
curl --user "${GITEA_USER}:${GITEA_TOKEN}" \
     --upload-file s2oj-gcc-$GCC_VERSION~1baoshuo1.deb \
     ${GITEA_ENDPOINT}/api/packages/${GITEA_USER}/debian/pool/all/main/upload