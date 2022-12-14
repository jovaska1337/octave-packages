# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:21 +0200
EAPI=8

inherit octave

DESCRIPTION="ZeroMQ bindings for GNU Octave."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/zeromq/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/zeromq-1.5.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	net-libs/zeromq
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
