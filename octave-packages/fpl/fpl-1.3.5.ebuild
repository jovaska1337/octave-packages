# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:46 +0200
EAPI=8

inherit octave

DESCRIPTION="Collection of routines to export data produced by Finite Elements or Finite Volume Simulations in formats used by some visualization programs."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/fpl/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/fpl-1.3.5.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.2.3"
DEPEND="${RDEPEND}"
