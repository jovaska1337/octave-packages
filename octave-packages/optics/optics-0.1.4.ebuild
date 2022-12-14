# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:02 +0200
EAPI=8

inherit octave

DESCRIPTION="Functions covering various aspects of optics."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/optics/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/optics-0.1.4.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.2.0"
DEPEND="${RDEPEND}"
