# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:50 +0200
EAPI=8

inherit octave

DESCRIPTION="Basic Octave implementation of mqtt toolkit"
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave-mqtt/code/ci/default/tree"

SRC_URI="
	https://downloads.sourceforge.net/project/octave-mqtt/v0.0.1/octave-mqtt-0.0.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	dev-python/paho-mqtt
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
