# Autogenerated by ./octave.sh on Tue, 08 Nov 2022 22:23:02 +0200
EAPI=8

inherit octave

DESCRIPTION="ONSAS is an Open Nonlinear Structural Analysis Solver. It is a GNU-Octave code for static/dynamic and linear/non-linear analysis of structures formed by solid, beam, truss or plane components."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://github.com/ONSAS/ONSAS.m/"

SRC_URI="
https://github.com/ONSAS/ONSAS.m/archive/refs/tags/v0.2.5.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=sci-mathematics/octave-4.0.0"
DEPEND="${RDEPEND}"
