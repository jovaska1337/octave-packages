# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:24 +0200
EAPI=8

inherit octave

DESCRIPTION="3D graphics using VRML."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/vrml/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/vrml-1.0.13.tar.gz -> ${P}.tar.gz"
RDEPEND="
	octave-packages/miscellaneous
	octave-packages/struct
	>=sci-mathematics/octave-2.9.7
	octave-packages/linear-algebra
	octave-packages/statistics"
DEPEND="${RDEPEND}"
