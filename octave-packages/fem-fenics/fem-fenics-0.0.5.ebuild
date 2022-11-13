# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:06 +0200
EAPI=8

inherit octave

DESCRIPTION="Resolution of partial differential equations based on fenics."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/fem-fenics/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/fem-fenics-0.0.5.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"
