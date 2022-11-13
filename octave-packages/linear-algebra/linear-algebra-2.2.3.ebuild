# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:58 +0200
EAPI=8

inherit octave

DESCRIPTION="Additional linear algebra code, including matrix functions."
LICENSE="GPL-3.0-or-later LGPL-3.0-or-later BSD-2-Clause-FreeBSD"
HOMEPAGE="https://sourceforge.net/p/octave/linear-algebra/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/linear-algebra-2.2.3.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
