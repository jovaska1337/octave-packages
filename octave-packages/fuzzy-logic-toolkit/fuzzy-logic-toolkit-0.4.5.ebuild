# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:08 +0200
EAPI=8

inherit octave

DESCRIPTION="A mostly MATLAB-compatible fuzzy logic toolkit for Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/fuzzy-logic-toolkit/ci/default/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/fuzzy-logic-toolkit-0.4.5.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-3.2.4"
DEPEND="${RDEPEND}"
