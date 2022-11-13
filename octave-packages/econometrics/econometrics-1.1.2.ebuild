# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:08 +0200
EAPI=8

inherit octave

DESCRIPTION="Econometrics."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/econometrics/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/econometrics-1.1.2.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-4.4.0
	octave-packages/optim"
DEPEND="${RDEPEND}"
