# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:26 +0200
EAPI=8

inherit octave

DESCRIPTION="Miscellaneous tools that don't fit somewhere else."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/miscellaneous/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/miscellaneous-1.3.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	sci-calculators/units
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"
