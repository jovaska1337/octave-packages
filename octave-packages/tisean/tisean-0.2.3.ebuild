# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:53 +0200
EAPI=8

inherit octave

DESCRIPTION="Nonlinear Time Series Analysis.  Port of TISEAN 3.0.1."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/tisean/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/tisean-0.2.3.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=octave-packages/signal-1.3.0
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
