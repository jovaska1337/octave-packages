# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:27 +0200
EAPI=8

inherit octave

DESCRIPTION="Parallel execution package."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/parallel/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/parallel-4.0.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=octave-packages/struct-1.0.12
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
