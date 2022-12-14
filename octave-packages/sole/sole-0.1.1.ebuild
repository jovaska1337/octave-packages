# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:49:15 +0200
EAPI=8

inherit octave

DESCRIPTION="A package for transient and steady state simulation of organic solar cells."
LICENSE="GPL-2.0-or-later"
HOMEPAGE="https://sourceforge.net/p/sole/git/ci/master/tree/"

SRC_URI="
	https://sourceforge.net/projects/sole/files/latest/download -> ${P}.tar.gz"
RDEPEND="
	>=octave-packages/bim-1.0.0
	>=sci-mathematics/octave-7.3.0"
DEPEND="${RDEPEND}"
