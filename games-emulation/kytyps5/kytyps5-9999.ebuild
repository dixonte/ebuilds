# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
 
EAPI=8

inherit cmake

DESCRIPTION="KytyPS5 is a free and open-source PlayStation 5 emulator"
HOMEPAGE="https://github.com/KytyPS5/KytyPS5"

if [[ "${PV}" == "9999" ]] ; then
        inherit git-r3
        EGIT_REPO_URI="https://github.com/KytyPS5/KytyPS5.git"
else
        #MY_VER=`grep '2026.10.01-r3' {$FILESDIR}/version.map | awk '{print $2}'`
        MY_VER="KytyPS5-2026-10-01-b3e419f"
        SRC_URI="
            https://github.com/KytyPS5/KytyPS5/archive/refs/tags/${MY_VER}.tar.gz -> ${P}.tar.gz
        "
        S="${WORKDIR}/KytyPS5-${MY_VER}"
        KEYWORDS="~amd64"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""
 
DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="
    llvm-core/clang
"

RESTRICT="network-sandbox"

src_prepare() {
    default
    cmake_prepare
}

src_configure() {
    default

    #local mycmakeargs=(
    #    -S "${S}"
    #    -B "${BUILD_DIR}"
    #    -G Ninja
    #    -DCMAKE_BUILD_TYPE=Release
    #    -DCMAKE_C_COMPILER=clang
    #    -DCMAKE_CXX_COMPILER=clang++
    #)
    #cmake_src_configure
    cd "${S}"
    cmake -S . -B "${BUILD_DIR}" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
}

src_compile() {
    cmake --build "${BUILD_DIR}" --target launcher --parallel
    #cmake_src_compile -C "${BUILD_DIR}" launcher
}

src_install() {
    dodir /opt/kytyps5
    cmake --install "${BUILD_DIR}" --prefix "${D}/opt/kytyps5"
    #cmake_src_install --prefix "${D}/opt/kytyps5"
}