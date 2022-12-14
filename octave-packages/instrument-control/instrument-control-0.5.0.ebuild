# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:09 +0200
EAPI=8

inherit octave

DESCRIPTION="Low level I/O functions for serial, i2c, parallel, tcp, gpib, vxi11, udp and usbtmc interfaces."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/instrument-control/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/instrument-control-0.5.0.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"
