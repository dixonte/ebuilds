# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

inherit desktop wrapper xdg-utils

DESCRIPTION="The world's most loved .NET and game dev IDE, by JetBrains"
HOMEPAGE="https://www.jetbrains.com/rider/"
SRC_URI="https://download.jetbrains.com/rider/JetBrains.Rider-${PV}.tar.gz"

# to keep it tidy.
S="${WORKDIR}/JetBrains Rider-${PV}"

LICENSE="idea-eap-EULA"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+bundled-jdk"
RESTRICT="bindist mirror"
QA_PREBUILT="opt/Rider/*"

BDEPEND="dev-util/patchelf"

RDEPEND="!bundled-jdk? ( >=virtual/jre-1.8 )
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-debug/gdb
	dev-debug/lldb
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/freetype:2
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libXxf86vm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	virtual/dotnet-sdk
"

src_prepare() {
	default

	local remove_me=(
		Install-Linux-tar.txt
		plugins/remote-dev-server/selfcontained
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-arm64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-darwin-arm64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-darwin-amd64
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-windows-arm64.exe
		plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-windows-amd64.exe
		plugins/platform-ijent-impl/ijent-aarch64-unknown-linux-musl-release
		lib/async-profiler/aarch64
	)

	rm -rv "${remove_me[@]}" || die

	sed -i \
		-e "\$a\\\\" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$a# Disable automatic updates as these are handled through Gentoo's" \
		-e "\$a# package manager. See bug #704494" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$aide.no.platform.update=Gentoo" bin/idea.properties

	for file in "jbr/lib/"/{libjcef.so,jcef_helper}
	do
		if [[ -f "${file}" ]]; then
			patchelf --set-rpath '$ORIGIN' ${file} || die
		fi
	done
}

src_install() {
	local DIR="/opt/Rider"
	local JRE_DIR="jbr"

	insinto ${DIR}
	doins -r *

	fperms 755 "${DIR}"/bin/{format.sh,fsnotifier,inspect.sh,jetbrains_client.sh,ltedit.sh,rider,rider.sh,repair,restarter}
	fperms 755 "${DIR}"/lib/ReSharperHost/linux-x64/{JetBrains.Debugger.Worker,JetBrains.ProcessEnumerator.Worker,Rider.Backend}
	fperms 755 "${DIR}/${JRE_DIR}"/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${DIR}"/${JRE_DIR}/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}

	if ! use bundled-jdk; then
		rm -r "${D}/${DIR}/${JRE_DIR}" || die
	fi

	make_wrapper "rider" "${DIR}/bin/rider"
	newicon "bin/rider.svg" "rider.svg"
	make_desktop_entry "rider" "Rider" "rider" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
