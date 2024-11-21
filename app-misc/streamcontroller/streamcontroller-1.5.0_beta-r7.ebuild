# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3
inherit systemd

DESCRIPTION="An elegant Linux app for the Elgato Stream Deck with support for plugins"

HOMEPAGE="https://github.com/StreamController/StreamController"

EGIT_REPO_URI="https://github.com/StreamController/StreamController.git"
EGIT_COMMIT="${PV/_/-}${PR/r/\.}"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"

SLOT="0"
RESTRICT="network-sandbox"

RDEPEND="
    >=dev-lang/python-3
	>=dev-libs/libportal-0.7.1
"

DEPEND="
    ${RDEPEND}
    dev-python/pip
"

src_prepare() {
	einfo "Creating .venv..."
	python3 -m venv create .venv || die "Failed setting up .venv"

	default
}

src_configure() {
	einfo "Gathering requirements via pip..."
	.venv/bin/pip install -r requirements.txt || die "Failed to install requirements"
}

src_compile() {
	true
}

src_install() {
	dodir /opt/
	cp -R "${S}" "${D}/opt/streamcontroller" || die "Failed copying files."

	dodir /usr/bin/
	cp "${FILESDIR}/streamcontroller" "${D}/usr/bin/" || die "Failed copying entrypoint script."

	dodir /usr/lib/systemd/user/
	cp "${FILESDIR}/streamcontroller.service" "${D}/usr/lib/systemd/user/" || die "Failed copying user system file."

	dodir /usr/share/applications/
	cp "${FILESDIR}/StreamController.desktop" "${D}/usr/share/applications/" || die "Failed copying desktop file."
}
