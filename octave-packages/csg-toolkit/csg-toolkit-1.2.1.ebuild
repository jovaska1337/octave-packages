# Autogenerated by ./octave.sh on Sun, 13 Nov 2022 14:48:45 +0200
EAPI=8

inherit octave

DESCRIPTION="The present set of GNU Octave functions provides a novel and robust algorithm for analyzing the diaphyseal cross-sectional geometric properties of long bones, which can be applied to any 3D digital model of a humerus, ulna, femur or tibia bone represented as a triangular mesh in a Wavefront OBJ file format."
LICENSE="GPL-3.0-or-later"
HOMEPAGE="https://github.com/pr0m1th3as/csg-toolkit"

SRC_URI="
	https://github.com/pr0m1th3as/long-bone-diaphyseal-CSG-Toolkit/raw/master/csg-toolkit-1.2.1.tar.gz -> ${P}.tar.gz"
RDEPEND="
	>=octave-packages/io-2.6.3
	>=octave-packages/matgeom-1.2.2
	>=sci-mathematics/octave-5.2.0
	>=octave-packages/statistics-1.4.2"
DEPEND="${RDEPEND}"
