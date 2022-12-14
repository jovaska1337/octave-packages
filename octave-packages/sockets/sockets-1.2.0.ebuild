# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:27 +0200
EAPI=8

inherit octave

DESCRIPTION="Socket functions for networking from within Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/sockets/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/sockets-1.2.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.2.0"
DEPEND="${RDEPEND}"
