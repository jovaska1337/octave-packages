# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:06 +0200
EAPI=8

inherit octave

DESCRIPTION="Signal processing tools, including filtering, windowing and display functions."
LICENSE="GPL-3.0-or-later public-domain"
HOMEPAGE="https://sourceforge.net/p/octave/signal/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/signal-1.4.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=octave-packages/control-2.4.0
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"
