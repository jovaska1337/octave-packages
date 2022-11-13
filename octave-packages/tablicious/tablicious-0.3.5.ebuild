# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:14 +0200
EAPI=8

inherit octave

DESCRIPTION="Matlab-compatible Octave table class for storing tabular/relational data. Similar to R and Python Pandas DataFrames."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://github.com/apjanke/octave-tablicious/"

SRC_URI="
	https://github.com/apjanke/octave-tablicious/archive/v0.3.5.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
