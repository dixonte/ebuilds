# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

inherit git-r3 linux-mod-r1

DESCRIPTION="Your GeForce runs AI at half speed. This fixes it."
HOMEPAGE="https://github.com/Zagitta/gpu-unlock"

EGIT_REPO_URI="https://github.com/Zagitta/gpu-unlock.git"

LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"

SLOT="0"
RESTRICT="network-sandbox"

CONFIG_CHECK="PCI"
MODULES_KERNEL_MIN=6.1          # Guess?

RDEPEND="
"

DEPEND="
        ${RDEPEND}
"

src_unpack() {
        default

        git-r3_fetch
        git-r3_checkout
}

src_prepare() {
        default

	cd "${WORKDIR}/${P}"

	make dist assets DISTDIR="${WORKDIR}/${P}/build"
}

src_configure() {
        true
}

src_compile() {
        cd "${WORKDIR}/${P}/kernel/gpu_unlock"

        emake "${MODULES_MAKEARGS[@]}" KV_FULL="${KV_FULL}"
}

src_install() {
        cd "${WORKDIR}/${P}"

	make install-dracut DESTDIR="${D}"
	make install-firmware DESTDIR="${D}"

        linux_moduleinto kernel/gpu_unlock
        linux_domodule kernel/gpu_unlock/gpu_unlock.ko
}
