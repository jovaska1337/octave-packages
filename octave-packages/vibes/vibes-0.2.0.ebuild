# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:38 +0200
EAPI=8

inherit octave

DESCRIPTION="Interface to VIBes, Visualizer for Intervals and Boxes."
LICENSE="GPL-3.0-or-later and MIT"
HOMEPAGE="https://sourceforge.net/p/octave/vibes/ci/octave-api/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/vibes-0.2.0.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"