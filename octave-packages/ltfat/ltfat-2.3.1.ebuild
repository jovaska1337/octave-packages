# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:19 +0200
EAPI=8

inherit octave

DESCRIPTION="The Large Time/Frequency Analysis Toolbox (LTFAT) is a Matlab/Octave toolbox for working with time-frequency analysis, wavelets and signal processing. It is intended both as an educational and a computational tool.  The toolbox provides a large number of linear transforms including Gabor and wavelet transforms along with routines for constructing windows (filter prototypes) and routines for manipulating coefficients."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://sourceforge.net/p/octave/ltfat/ci/master/tree/"

SRC_URI="
	https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/ltfat-2.3.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-3.8.0"
DEPEND="${RDEPEND}"
