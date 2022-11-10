# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:02 +0200
EAPI=8

inherit octave

DESCRIPTION="Solving DC and transient electrical circuit equations."
LICENSE="GPL-2.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/ocs/ci/master/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/ocs-0.1.5.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-3.0.0"
DEPEND="${RDEPEND}"