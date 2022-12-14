# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:57 +0200
EAPI=8

inherit octave

DESCRIPTION="Algorithms for smoothing noisy data."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/data-smoothing/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/data-smoothing-1.3.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.6.0
	>=octave-packages/optim-1.0.3"
DEPEND="${RDEPEND}"
