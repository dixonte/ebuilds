# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils
#inherit cmake

DESCRIPTION="G-code generator for 3D printers (Bambu, Prusa, Voron, VzBot, RatRig, Creality, etc.)"

HOMEPAGE="https://github.com/SoftFever/OrcaSlicer"

INSTALL_DIR="/opt/orcaslicer/"

if [[ ${PV} == 9999 ]]; then
    EGIT_REPO_URI="https://github.com/SoftFever/OrcaSlicer"
    EGIT_BRANCH="main"
    #EGIT_CHECKOUT_DIR="${S}${INSTALL_DIR}"
    inherit git-r3
    SRC_URI=""
    MY_PV=${PV//_}
    MY_PN="OrcaSlicer"
    MY_P=${MY_PN}-${MY_PV}
    S="${WORKDIR}/${MY_P}"
else
    MY_PV=${PV//_}
    MY_PN="OrcaSlicer"
    MY_P=${MY_PN}-${MY_PV}
    SRC_URI="https://github.com/SoftFever/OrcaSlicer/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"
    KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}"
fi

IUSE="debug"

LICENSE="AGPL-3"

SLOT="0"
RESTRICT="network-sandbox"

RDEPEND="
	>=net-misc/curl-8
	>=sys-apps/dbus-1
	>=gui-libs/eglexternalplatform-1
    >=kde-frameworks/extra-cmake-modules-6
    >=sys-apps/file-5
    >=sys-devel/gettext-0.21
    >=media-libs/glew-2
    >=media-libs/gstreamer-1
    >=gui-libs/gtk-3
    >=dev-libs/libmspack-1
    >=app-crypt/libsecret-0.21
    >=dev-libs/libspnav-1
    >=media-libs/mesa-25
    >=dev-build/ninja-1
    >=dev-libs/openssl-3
    >=sys-apps/texinfo-7
    >=dev-libs/wayland-1
    >=dev-libs/wayland-protocols-1
    >=net-libs/webkit-gtk-2.44
    >=net-misc/wget-1
"

DEPEND="
    ${RDEPEND}
    >=dev-build/cmake-3
    >=dev-util/patchelf-0.18
"

src_prepare() {
    if [[ -e "${FILESDIR}/${PF}.patch" ]]; then
        PATCHES+=( "${FILESDIR}/${PF}.patch" )
    fi

    default

    SCRIPT_PATH="${WORKDIR}/${MY_P}"
    SLIC3R_PRECOMPILED_HEADERS="ON"
    COLORED_OUTPUT="-DCOLORED_OUTPUT=ON"

    cd "$SCRIPT_PATH"

    einfo "Changing date in version..."
    # change date in version
    sed --in-place "s/+UNKNOWN/_$(date '+%F')/" version.inc || die "Could not change version.inc"
    einfo "done"

    einfo "Script path: $SCRIPT_PATH"

    # cmake 4.x compatibility workaround
    CMAKE_POLICY_VERSION_MINIMUM=3.5
}

src_compile() {
    cd "$SCRIPT_PATH"

    einfo "Building dependencies..."
    BUILD_ARGS="${DEPS_EXTRA_BUILD_ARGS} -DDEP_WX_GTK3=ON"
    mkdir deps/build

    if use debug ; then
        # build deps with debug and release else cmake will not find required sources
        mkdir deps/build/release
        cmake -S deps -B deps/build/release -DSLIC3R_PCH=${SLIC3R_PRECOMPILED_HEADERS} -G Ninja \
            -DDESTDIR="${SCRIPT_PATH}/deps/build/destdir" \
            -DDEP_DOWNLOAD_DIR="${SCRIPT_PATH}/deps/DL_CACHE" \
            ${COLORED_OUTPUT} \
            ${BUILD_ARGS} \
            || die "Failed configuring dependencies (release)."
        cmake --build deps/build/release || die "Failed building dependencies (release)."
        BUILD_ARGS="${BUILD_ARGS} -DCMAKE_BUILD_TYPE=Debug"
    fi

    CMAKE_CMD="cmake -S deps -B deps/build -G Ninja ${COLORED_OUTPUT} ${BUILD_ARGS}"
    einfo "${CMAKE_CMD}"
    ${CMAKE_CMD} || die "Failed configuring dependencies."
    ABI="" cmake --build deps/build || die "Failed building dependencies."


    einfo "Configurint OrcaSlicer..."
    BUILD_ARGS="${ORCA_EXTRA_BUILD_ARGS} -DSLIC3R_GTK=3"
    if use debug ; then
        BUILD_ARGS="${BUILD_ARGS} -DCMAKE_BUILD_TYPE=Debug -DBBL_INTERNAL_TESTING=1"
    else
        BUILD_ARGS="${BUILD_ARGS} -DBBL_RELEASE_TO_PUBLIC=1 -DBBL_INTERNAL_TESTING=0"
    fi


    CMAKE_CMD="cmake -S . -B build -G Ninja \
        -DSLIC3R_PCH=${SLIC3R_PRECOMPILED_HEADERS} \
        -DCMAKE_PREFIX_PATH="${SCRIPT_PATH}/deps/build/destdir/usr/local" \
        -DSLIC3R_STATIC=1 \
        -DORCA_TOOLS=ON \
        ${COLORED_OUTPUT} \
        ${BUILD_ARGS}"
    einfo "${CMAKE_CMD}"
    ${CMAKE_CMD} || die "Failed configuring OrcaSlicer."
    einfo "done"

    einfo "Building OrcaSlicer ..."
    cmake --build build --target OrcaSlicer || die "Failed building OrcaSlicer."
    einfo "Building OrcaSlicer_profile_validator .."
    cmake --build build --target OrcaSlicer_profile_validator || die "Failed building OrcaSlicer_profile_validator."
    ./run_gettext.sh || die "Failed run_gettext.sh."
    einfo "done"

    true
}

src_install() {
    dodir /opt/orcaslicer/bin/
    mkdir -p "${D}/opt/orcaslicer/bin" || die "Failed to create /opt/orcaslicer/bin"
    cp "$SCRIPT_PATH/build/src/orca-slicer" "${D}/opt/orcaslicer/bin/" || die "Failed copying orca-slicer binary"
    patchelf --remove-rpath "${D}/opt/orcaslicer/bin/orca-slicer" || die "Failed patching orca-slicer binary"

    dodir /opt/orcaslicer/resources/
    cp -R "$SCRIPT_PATH/resources" "${D}/opt/orcaslicer/" || die "Failed copying resources dir"

    cat << EOF > "${D}/opt/orcaslicer/orca-slicer"
#!/bin/bash
DIR=\$(readlink -f "\$0" | xargs dirname)
export LD_LIBRARY_PATH="\$DIR/bin:\$LD_LIBRARY_PATH"

# FIXME: OrcaSlicer segfault workarounds
# 1) OrcaSlicer will segfault on systems where locale info is not as expected (i.e. Holo-ISO arch-based distro)
export LC_ALL=C

if [ "\$XDG_SESSION_TYPE" = "wayland" ] && [ "\$ZINK_DISABLE_OVERRIDE" != "1" ]; then
    if command -v glxinfo >/dev/null 2>&1; then
        RENDERER=\$(glxinfo | grep "OpenGL renderer string:" | sed 's/.*: //')
        if echo "\$RENDERER" | grep -qi "NVIDIA"; then
            if command -v nvidia-smi >/dev/null 2>&1; then
                DRIVER_VERSION=\$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
                DRIVER_MAJOR=\$(echo "\$DRIVER_VERSION" | cut -d. -f1)
                [ "\$DRIVER_MAJOR" -gt 555 ] && ZINK_FORCE_OVERRIDE=1
            fi
            if [ "\$ZINK_FORCE_OVERRIDE" = "1" ]; then
                export __GLX_VENDOR_LIBRARY_NAME=mesa
                export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
                export MESA_LOADER_DRIVER_OVERRIDE=zink
                export GALLIUM_DRIVER=zink
                export WEBKIT_DISABLE_DMABUF_RENDERER=1
            fi
        fi
    fi
fi
exec "\$DIR/bin/orca-slicer" "\$@"
EOF
    chmod +x "${D}/opt/orcaslicer/orca-slicer" || die "Failed to set execute bit on launch script."

    mkdir -p "${D}/usr/share/icons/hicolor/32x32/apps/"
    cp "$SCRIPT_PATH/resources/images/OrcaSlicer_32px.png" "${D}/usr/share/icons/hicolor/32x32/apps/OrcaSlicer.png"
    mkdir -p "${D}/usr/share/icons/hicolor/64x64/apps/"
    cp "$SCRIPT_PATH/resources/images/OrcaSlicer_64.png" "${D}/usr/share/icons/hicolor/64x64/apps/OrcaSlicer.png"
    mkdir -p "${D}/usr/share/icons/hicolor/128x128/apps/"
    cp "$SCRIPT_PATH/resources/images/OrcaSlicer_128px.png" "${D}/usr/share/icons/hicolor/128x128/apps/OrcaSlicer.png"
    mkdir -p "${D}/usr/share/icons/hicolor/192x192/apps/"
    cp "$SCRIPT_PATH/resources/images/OrcaSlicer_192px.png" "${D}/usr/share/icons/hicolor/192x192/apps/OrcaSlicer.png"

    mkdir -p "${D}/usr/share/applications/"
    cat << EOF > "${D}/usr/share/applications/orca-slicer.desktop"
[Desktop Entry]
Type=Application
Name=Orca Slicer
GenericName=3D Printer Slicer
Comment=Next-Gen Slicing Software for Precision 3D Prints
Icon=OrcaSlicer
Exec=/opt/orcaslicer/orca-slicer %U
Categories=Utility;
MimeType=x-scheme-handler/bambustudio;model/stl;application/vnd.ms-3mfdocument;application/prs.wavefront-obj;application/x-amf;
EOF

    true
}

pkg_postinst() {
    xdg_desktop_database_update
}

pkg_postrm() {
    xdg_desktop_database_update
}	
