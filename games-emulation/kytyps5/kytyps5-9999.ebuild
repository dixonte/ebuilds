# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="KytyPS5 is a free and open-source PlayStation 5 emulator"
HOMEPAGE="https://github.com/KytyPS5/KytyPS5"

EGIT_REPO_URI="https://github.com/KytyPS5/KytyPS5.git"
EGIT_SUBMODULES=( '*' )

if [[ ${PV} != 9999 ]]; then
        # KytyPS5-2026-10-13-9e41d83
        EGIT_COMMIT="9e41d8320a2774b303fbad344c2347e8d0292e83"
        KEYWORDS="~amd64"
fi

LICENSE="GPL-2"
SLOT="0"

DEPEND="
        ${RDEPEND}
        dev-qt/qtbase:6[dbus,gui,network,ssl,widgets,wayland,X]
        dev-qt/qtsvg:6
        dev-qt/qtwayland:6
        dev-util/vulkan-headers
"
RDEPEND="
        app-arch/zstd
        dev-libs/double-conversion
        dev-libs/glib:2
        app-crypt/libb2
        dev-libs/libinput
        dev-libs/libpcre2[pcre16]
        dev-libs/md4c
        dev-libs/openssl
        dev-libs/wayland
        media-libs/alsa-lib
        media-libs/fontconfig
        media-libs/freetype
        media-libs/harfbuzz
        media-libs/libglvnd
        media-libs/libjpeg-turbo
        media-libs/libpng
        media-libs/vulkan-loader
        net-libs/libproxy
        sys-apps/dbus
        virtual/libudev
        virtual/zlib
        x11-libs/libICE
        x11-libs/libSM
        x11-libs/libX11
        x11-libs/libXcursor
        x11-libs/libXext
        x11-libs/libXfixes
        x11-libs/libXi
        x11-libs/libXrandr
        x11-libs/libXScrnSaver
        x11-libs/libdrm
        x11-libs/libxcb
        x11-libs/libxkbcommon[X]
        x11-libs/xcb-util-cursor
        x11-libs/xcb-util-image
        x11-libs/xcb-util-keysyms
        x11-libs/xcb-util-renderutil
        x11-libs/xcb-util-wm
"
BDEPEND="
dev-libs/wayland-protocols
        dev-util/vulkan-headers
        dev-util/wayland-scanner
        llvm-core/clang
        virtual/pkgconfig
"

# zarchive is fetched by CMake FetchContent during configure
RESTRICT="network-sandbox"

src_prepare() {
        # old bundled cpuinfo lacks <ctype.h>; clang >= 16 makes that an error
        sed -i '1i #include <ctype.h>' \
                3rdparty/cpuinfo/src/arm/linux/chipset.c || die

        # qt.conf is written without DESTDIR -> sandbox violation
        sed -i 's|\\"\\${CMAKE_INSTALL_PREFIX}/qt\.conf|\\"\\$ENV{DESTDIR}\\${CMAKE_INSTALL_PREFIX}/qt.conf|' \
                src/launcher/CMakeLists.txt || die
        grep -q 'ENV{DESTDIR}.*qt\.conf' src/launcher/CMakeLists.txt \
                || die "qt.conf DESTDIR patch did not apply"

        cmake_src_prepare
}

src_configure() {
        export CC=clang CXX=clang++

        local mycmakeargs=(
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_INSTALL_PREFIX="${EPREFIX}/opt/kytyps5"
        )
        cmake_src_configure
}

src_compile() {
        cmake_src_compile launcher
}

src_install() {
        cmake_src_install

        # bundled static libs / headers / cmake configs are build-only
        rm -r "${ED}"/opt/kytyps5/{include,lib64} || die

        dosym ../../opt/kytyps5/launcher /usr/bin/kytyps5
}

QA_PREBUILT="opt/kytyps5/*"
