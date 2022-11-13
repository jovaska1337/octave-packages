# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:48 +0200
EAPI=8

inherit octave

DESCRIPTION="Audio and MIDI Toolbox for GNU Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/audio/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/audio-2.0.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	media-libs/rtmidi
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
