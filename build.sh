#!/bin/bash

CURRENT_DIR=$(pwd)
GCC_VERSION=$(cat GCC_VERSION)
GCC_GIT="git://gcc.gnu.org/git/gcc.git"
GCC_SRC="${CURRENT_DIR}/../gcc"

build_cd() {
  cd $@
  echo "****** Now at: $(pwd)"
}

if [ -z "$GCC_VERSION" ]; then
  echo "GCC_VERSION not set!"
  exit 1
fi

# Clone GCC
echo "===> Cloning GCC..."
git clone -b "releases/gcc-$GCC_VERSION" --depth 1 "${GCC_GIT}" "${GCC_SRC}"

# Download prerequisites
echo "===> Downloading prerequisites..."
build_cd ${GCC_SRC}
./contrib/download_prerequisites
build_cd ${CURRENT_DIR}

# Apply patches
echo "===> Applying patches..."
build_cd ${GCC_SRC}
patch -p1 < ${CURRENT_DIR}/patches/gcc-$GCC_VERSION.patch
build_cd ${CURRENT_DIR}

# Configure GCC
echo "===> Configuring GCC..."
build_cd ${CURRENT_DIR}/build
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

# Prepare for packaging
echo "===> Preparing for packaging..."
make -j$(nproc) DESTDIR=${CURRENT_DIR}/deb install
build_cd ${CURRENT_DIR}/deb
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
build_cd ${CURRENT_DIR}
