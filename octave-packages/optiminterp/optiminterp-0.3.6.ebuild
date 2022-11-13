# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:45 +0200
EAPI=8

inherit octave

DESCRIPTION="An optimal interpolation toolbox providing functions to perform a n-dimensional optimal interpolations of arbitrarily distributed data points."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/optiminterp/ci/master/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/optiminterp-0.3.6.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.6.0"
DEPEND="${RDEPEND}"
