# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:51 +0200
EAPI=8

inherit octave

DESCRIPTION="Tools to compute spectral decompositions of irregularly-spaced time series. Functions based on the Lomb-Scargle periodogram and Adolf Mathias' implementation for R and C."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/lssa/ci/default/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/lssa-0.1.3.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.6.0"
DEPEND="${RDEPEND}"
