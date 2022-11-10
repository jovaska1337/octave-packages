# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:46 +0200
EAPI=8

inherit octave

DESCRIPTION="Provides basic joystick functions for GNU Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave-joystick/code/ci/default/tree"

SRC_URI="
https://downloads.sourceforge.net/project/octave-joystick/v0.0.1/joystick-0.0.1.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	media-libs/libsdl2
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
