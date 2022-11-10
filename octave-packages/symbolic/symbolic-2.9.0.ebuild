# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:22:15 +0200
EAPI=8

inherit octave

DESCRIPTION="Symbolic calculation features, including common Computer Algebra System tools such as algebraic operations, calculus, equation solving, Fourier and Laplace transforms, variable precision arithmetic and other features. Compatibility with other symbolic toolboxes is intended."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://github.com/cbm755/octsympy/"

SRC_URI="
https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/symbolic-2.9.0.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-4.2.0"
DEPEND="${RDEPEND}"
