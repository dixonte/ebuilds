# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3
inherit systemd

DESCRIPTION="Collect data from Sungrow Inverters using ModbusTcpClient, SungrowModbusTcpClient or SungrowModbusWebClient and export to various locations."

HOMEPAGE="https://github.com/bohdan-s/SunGather"

EGIT_REPO_URI="https://github.com/bohdan-s/SunGather.git"
EGIT_COMMIT="v${PV}"

LICENSE="GPL-3"
KEYWORDS="~amd64"

IUSE="+mqttv1"
SLOT="0"
RESTRICT="network-sandbox"

RDEPEND="
    >=dev-lang/python-3
    acct-user/nobody
    acct-group/nobody
"

DEPEND="
    ${RDEPEND}
    dev-python/pip
"

src_prepare() {
	cp requirements.txt SunGather/ || die "Could not find requirements.txt"
	pushd SunGather || die "Could not find SunGather/"

	einfo "Creating .venv..."
	python3 -m venv create .venv || die "Failed setting up .venv"

	einfo "Gathering requirements via pip..."
	.venv/bin/pip install -r requirements.txt || die "Failed to install requirements"
	popd

	if use mqttv1; then
		einfo "Patching MQTT client to use V1 API..."
		PATCHES+=( "${FILESDIR}"/${P}-mqttv1.patch )
	fi

	default
}

src_configure() {
	true
}

src_compile() {
	true
}

src_install() {
	dodir /opt/
	cp -R "${S}/SunGather" "${D}/opt/sungather" || die "Failed copying files."

	insinto /etc/
	newins "${S}/SunGather/config-example.yaml" "sungather-config.yaml"	

	systemd_dounit "${FILESDIR}"/sungather.service
}
