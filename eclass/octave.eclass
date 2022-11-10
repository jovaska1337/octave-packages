# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: octave.eclass
# @MAINTAINER: Juho Ovaska
# @AUTHOR: Juho Ovaska
# @SUPPORTED_EAPIS: 8
# @BLURB: GNU Octave package helper eclass. 
# @DESCRIPTION:
# A helper eclass for installing GNU Octave packages through
# portage. Based on g-octave.eclass and the octave forge Makefile.

# no slotting
SLOT=0

# keywording
if [[ "$PV" == 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~x86"
fi

# evaluate octave script
_octave_eval() {
	local args=( --no-history --no-site-file --no-gui --silent --eval )
	local octave="$(type -p octave)" || return 1
	"${octave}" "${args[@]}" "$1" || return 1
}

# rebuild octave package database
_octave_rebuild() {
	_octave_eval "pkg('rebuild');" &>/dev/null || return 1
}

# get octave data and library directory
_octave_dirs() {
	# get the octave-config binary
	local octave_config="$(type -p octave-config)" || return 1

	# get locations from octave-config
	local -n _paths="$1"

	_paths+=("$("${octave_config}" -p OCTLIBDIR)")
	_paths+=("$("${octave_config}" -p DATADIR)")

	# sanity check
	for path in "${_paths[@]}"; do
		[[ -d "$path" ]] || return 1
	done
}

# setup environment for compilation
_octave_env() {
		# get octave libdir
		local paths=()
		_octave_dirs paths || return 1

		# add the octave library path to LDFLAGS manually because it's
		# not found by configure scripts automatically for some reason
		export LDFLAGS="${LDFLAGS} -L\"${paths[0]}\""

		# include path fixes, add per package as trying to automate
		# this will cause way more pain than it actually resolves
		local include=( fltk )

		# generate CPATH
		local include_path=""
		for dir in "${include[@]}"; do
			include_path="${include_path}:/usr/include/${dir}"
		done < <(find /usr/include -mindepth 1 -maxdepth 1 -type d)
		include_path="${include_path##:}"

		# these control the include path for gcc
		[[ "$include_path" ]] \
			&& export CPATH="$include_path" \
			&& export CXXPATH="$include_path"

		# some packages don't fall back to calling mkoctfile
		export MKOCTFILE=mkoctfile
}

EXPORT_FUNCTIONS \
	src_unpack \
	src_configure \
	src_compile \
	src_install \
	pkg_postinst \
	pkg_prerm \
	pkg_postrm

octave_src_unpack() {
	# unpack first
	default_src_unpack

	# find name of unpacked directory
	# (differs for some packages like websockets)
	local name="$(find "${WORKDIR}" -type d \
		-mindepth 1 -maxdepth 1 | head -n1)"
	name="${name##*/}"

	# make the source dir name the package name
	if [[ "$name" != "$PN" ]]; then
		mv "${WORKDIR}/${name}" "${WORKDIR}/${PN}" || die
	fi

	# set source directory
	S="${WORKDIR}/${PN}"
}

octave_src_configure() {
	# run configure script for native code
	if [[ -e "${S}/src/configure" ]]; then
		cd "${S}/src"

		# setup compilation environment
		_octave_env || die

		./configure || die
	fi
}

octave_src_compile() {
	# compile native code
	if [[ -e "${S}/src/Makefile" ]]; then
		cd "${S}/src"

		# setup environment if source didn't
		# have a configure script
		if [[ ! -e "${S}/src/configure" ]]; then
			_octave_env || die
		fi

		# run make
		emake || die
	fi
}

octave_src_install() {
	cd ..

	# get octave dirs
	local paths=()
	_octave_dirs paths || die

	# convert to proper paths in the image
	local lib="${D}/${paths[0]}"
	local share="${D}/${paths[1]}/octave"

	# make sure octave package directories exist
	mkdir -p "${lib}/packages" || die
	mkdir -p "${share}/packages" || die

	# remove configure and Makefile, so
	# octave doesn't re-run them
	if [[ -d "${S}/src" ]]; then
		rm "${S}/src/Makefile" 2>/dev/null
		rm "${S}/src/configure" 2>/dev/null
	fi

	# install package
	einfo "Installing package with octave."
	_octave_eval "
		warning('off', 'all');
		pkg('prefix', '${share}/packages','${lib}/packages');
		pkg('global_list', '${lib}/octave_packages');
		pkg('local_list', '${share}/octave_packages');
		pkg('install', '-nodeps', '-verbose', '${PN}');" \
			|| die "Failed to install package."

	# get package directory (in install image)
	# and remove package indecies from image
	local pkgdir="$(_octave_eval "
		warning('off', 'all');
		pkg('prefix', '${share}/packages','${lib}/packages');
		pkg('global_list', '${lib}/octave_packages');
		pkg('local_list', '${share}/octave_packages');
		tmp = pkg('list');
		tmp = pkg('list');
		unlink(pkg('local_list'));
		unlink(pkg('global_list'));
		tmp = tmp{cellfun(@(x) strcmp(x.name, '${PN}'), tmp)};
		disp(tmp.dir);")" || die "Failed to get package directory."

	# create uninstall prevention script
	einfo "Adding uninstall prevention script."
	local script="${pkgdir}/packinfo/on_uninstall.m"
	if [[ -e "$script" ]]; then
		mv "$script" "${script}.old" || die
	fi
	echo "function on_uninstall(desc)" > "$script"
	echo "  error('%s must be uninstalled through portage.', desc.name);" \
		> "$script"
	echo "end" > "$script";

	# install docs
	if [[ -d doc/ ]]; then
		einfo "Installing package documentation."
		dodoc -r doc/* || die "Failed to install docs."
	fi
}

octave_pkg_postinst() {
	einfo "Registering ${PN} in the Octave package database."
	_octave_rebuild || die "Failed to register the package."
}

octave_pkg_prerm() {
	# find where the package is installed
	local pkgdir=$(_octave_eval "
		pkg('rebuild');
		tmp = pkg('list');
		tmp = tmp{cellfun(@(x) strcmp(x.name, '${PN}'), tmp)};
		disp(tmp.dir);") || die "Failed to locate package directory."

	# this directory should exist for a valid package
	cd "${pkgdir}/packinfo" || die

	# remove uninstall prevention script (should always exist)
	rm on_uninstall.m || die

	# check if the original on_uninstall.m exists
	[[ -f on_uninstall.m.old ]] || return
	mv on_uninstall.m.old on_uninstall.m || die

	einfo "Running on_uninstall.m to prepare for package removal."
	_octave_eval "
		tmp = pkg('list');
		tmp = tmp{cellfun(@(x) strcmp(x.name, '${PN}'), tmp)};
		on_uninstall(tmp);" &>/dev/null \
			|| die "Failed to execute on_uninstall.m"
}

octave_pkg_postrm() {
	einfo "Rebuilding the Octave package database."
	_octave_rebuild || die "Failed to rebuild the package database"
}
