# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:59 +0200
EAPI=8

inherit octave

DESCRIPTION="A toolbox for the McCabe-Thiele method for GNU Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://github.com/aumpierre-unb/McCabe-Thiele-for-GNU-Octave/"

SRC_URI="
https://github.com/aumpierre-unb/McCabe-Thiele-for-GNU-Octave/archive/refs/tags/v0.1.1.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"