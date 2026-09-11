# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

inherit git-r3 linux-mod-r1

DESCRIPTION="Driver for the Coral Apex m.2 board"
#HOMEPAGE=""

EGIT_REPO_URI="https://github.com/google/gasket-driver.git"

#LICENSE="GPL-3"
KEYWORDS="~x86 ~amd64"

SLOT="0"
RESTRICT="network-sandbox"

CONFIG_CHECK="PCI"
MODULES_KERNEL_MIN=6.1		# Guess?

RDEPEND="
"

DEPEND="
	${RDEPEND}
"

src_prepare() {
	git-r3_checkout https://github.com/jnicolson/gasket-builder.git "${WORKDIR}/${P}/gasket-builder"

	cd "${WORKDIR}/${P}"
	git apply gasket-builder/patches/*

	default
}

src_configure() {
	true
}

src_compile() {
	cd "${WORKDIR}/${P}/src"
	MODULES_MAKEARGS+=(
		NIH_KDIR="${KV_OUT_DIR}"
		NIH_KSRC="${KV_DIR}"
	)

	emake "${MODULES_MAKEARGS[@]}"
}

src_install() {
	cd "${WORKDIR}/${P}/src"

	linux_moduleinto kernel/misc
	linux_domodule apex.ko
	linux_domodule gasket.ko

	modules_post_process
	einstalldocs

	dodir "/etc/modules-load.d/"
	echo "apex" > "${ED}/etc/modules-load.d/apex"
}
