# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:25 +0200
EAPI=8

inherit octave

DESCRIPTION="Real-valued interval arithmetic. Handle uncertainties, estimate arithmetic errors, computer-assisted proofs, constraint programming, and verified computing."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/interval/ci/default/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/interval-3.2.0.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-libs/mpfr
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"