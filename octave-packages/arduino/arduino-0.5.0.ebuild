# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:45 +0200
EAPI=8

inherit octave

DESCRIPTION="Allow communication to a programmed arduino board to control its hardware."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/arduino/ci/default/tree/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/arduino-0.5.0.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=octave-packages/instrument-control-0.3.0
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"