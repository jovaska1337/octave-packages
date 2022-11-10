# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:03 +0200
EAPI=8

inherit octave

DESCRIPTION="A Drift-Diffusion simulator for 3d semiconductor devices."
LICENSE="GPL-2.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/ocs/ci/master/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/secs3d-0.0.1.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	octave-packages/bim
	octave-packages/fpl
	>=sci-mathematics/octave-3.2.4"
DEPEND="${RDEPEND}"
