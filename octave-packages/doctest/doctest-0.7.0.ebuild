# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:12 +0200
EAPI=8

inherit octave

DESCRIPTION="Documentation tests."
LICENSE="BSD-3-Clause"
HOMEPAGE="https://sourceforge.net/p/octave/doctest/ci/master/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/doctest-0.7.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-4.2.0"
DEPEND="${RDEPEND}"
