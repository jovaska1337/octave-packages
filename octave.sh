#!/bin/bash

# this script generates a portage repository from the GNU Octave
# package index, generating ebuilds for all packages whose
# dependencies can be resolved from the existing repositories.
# was bash the best "scripting language" to write this in?
# if you look below, the answer is clearly no, but what's done is done.

# the gentoo respositories seem to be missing the following libraries
# - gcdm (libgcdm)
# - biosig (libbiosig)
# the fact that these don't resolve is not a fault with this script

# FIXME: add support for command line args

# octave package index
octave_index="https://gnu-octave.github.io/packages/packages/"

# only create ebuilds for latest numbered versions
latest_only=1

# portage repository path
repositories="/var/db/repos"

# output path
output="${repositories}/octave"

# ebuild category for generated ebuilds
category="octave-packages"

# "builtin" packages (these don't resolve as a dependency)
declare -a octave_builtin
# the pkg package manager is built into octave
octave_builtin+=(pkg)
# this isn't a package anymore but we can force USE=sundials
# to have all the ODE solver available for use
octave_builtin+=(odepkg)

# packages to ignore from the repository
# (ie. ebuilds won't be created for these)
declare -a ignore_packages
# this is already built into octave
ignore_packages+=(pkg)
# as portage now handles the octave package
# management, I see no reason to include this
ignore_packages+=(packajoozle)
# example package, no need for an ebuild
ignore_packages+=(pkg-example)

# static translation rules for library names
# ('lib' prefix and '-dev' suffix removed)
declare -A static_rules
static_rules[avcodec]="media-video/ffmpeg"
static_rules[avformat]="media-video/ffmpeg"
static_rules[swscale]="media-video/ffmpeg"
static_rules[sqlite3]="dev-db/sqlite"
static_rules[zmq]="net-libs/zeromq"
static_rules[pq]="dev-db/postgresql"

# extra dependencies per package
declare -A extra_depends
# this is outright missing from the dependencies
extra_depends[fits]="sci-libs/cfitsio"
# symbolic is missing version information from the sympy
# dependency. doesn't work with >=sympy-1.6 at all
# (this is what you get when the devs use LTS distros)
extra_depends[symbolic]=">dev-python/sympy-1.6"

# FIXME: required octave useflags for packages should be
# collected here. for example image-aquisition requires
# fltk which is pulled in by octave when USE=opengl
declare -A required_use
required_use[image-aquisition]="opengl"

# gawk program to parse the index
read -r -d '' gawk_program << EOF
/^__pkg__/ {
	# make line modifiable
	line = \$0;

	# substitute HTML entities
	gsub("&gt;", ">", line);
	gsub("&lt;", "<", line);
	gsub("&amp;", "\\\&", line);
	gsub("&#39;", "'", line);

	# split into tokens
	# (will break if value contains escaped quotes)
	r = match(line, /^__pkg__\.\(([^)]+)\)\.(\S+)\s*=\s*("[^"]+");\$/, m)
	if (r != 0) {
		# concatenate and quote matches
		print m[1] " \"" m[2] "\" " m[3]
	}
}
EOF

# /etc/portage/repos.conf/octave.conf
read -r -d '' repo_conf <<EOF
[octave]
location = ${output}
masters = gentoo
EOF

# eclass/octave.eclass
read -r -d '' octave_eclass << EOF
# under development
EOF

# metadata/layout.conf
read -r -d '' layout_conf << EOF
# layout.conf
masters = gentoo
sign-commits = false
sign-manifests = false
EOF

# object creator
# FIXME: this code is shit, make it better
object() {
	# local variables
	local part
	local parts
	local value
	local where
	local index
	local target
	local _target
	local i
	local j

	# initial target
	target="$1"

	# value to set
	value="$3"

	# split query
	IFS=. read -a parts <<< "$2"
	i=1; j="${#parts[@]}"
	for where in "${parts[@]}"; do
		# possible index
		index="${where#*@}"
		[[ "$index" == "$where" ]] \
			&& index="" \
			|| where="${where%@*}"

		# new target for next loop
		_target="${target}_${where//-/_}"

		# prefix first generated array with _
		[[ "$i" == 1 ]] && _target="_${_target}"

		# not last item
		if [[ "$i" < "$j" ]]; then
			# create reference
			local -n _target_="$target"
			[[ "${_target_[$where]}" ]] \
				|| _target_["$where"]="@${_target}"

			# indexed array item
			if [[ "$index" ]]; then
				# create indexed array
				[[ -v "$_target" ]] \
					|| declare -ga "$_target"
				
				# new target
				local -n _target_="$_target"
				_target_["$index"]="@${_target}_${index}"
				_target=${_target_[$index]#@}
			fi

			# create new target if it doesn't exist
			[[ -v "$_target" ]] \
				|| declare -gA "$_target"

			# switch target
			target="$_target"

			# increase part number
			i=$(($i + 1))

		# last item -> set value
		else
			# indexed array item
			if [[ "$index" ]]; then
				# create indexed array
				[[ -v "$_target" ]] \
					|| declare -ga "$_target"

				# create reference
				local -n _target_="$target"
				_target_["$where"]="@${_target}"

				# set value
				local -n _target_="$_target"
				_target_["$index"]="$value"

			# associative array item
			else
				# set value
				local -n _target_="$target"
				_target_["$where"]="$value"
			fi
		fi
	done
}

# object resolver
_() {
	# local variables
	local index
	local value
	local steps
	local state
	local keys
	local key
	local i
	local j
	local k

	# initial object reference
	local -n obj="$1"

	# split query
	IFS=. read -a keys <<< "$2"

	# resolve query
	state=0; i=0
	for key in "${keys[@]}"; do
		# possible index
		index="${key#*@}"
		if [[ "$index" == "$key" ]]; then
			# unset index
			index=""
		else
			# strip index from key
			key="${key%@*}"

			# if index is empty, we return
			# the length of an array or if
			# extra keys are after this
			# the resolution will fail
			[[ "$index" ]] || state=3
		fi

		# resolve steps for key
		steps=("$key")
		[[ "$index" ]] && steps+=("$index")

		# resolve steps
		j=0; k="${#steps[@]}"
		for step in "${steps[@]}"; do
			# get value from current reference
			value="${obj[$step]}"

			# empty value (resolution fails)
			if [[ ! "$value" ]]; then
				return

			# if value starts with @, resolve deeper
			elif [[ "$value" == @* ]]; then
				local -n obj="${value#@}"

			# can't resolve further
			else
				state=1
			fi

			# increment step
			j=$(($j + 1))

			# break on nonzero state
			[[ "$state" != 0 ]] && break
		done

		# increment key count
		i=$(($i + 1))

		# break on nonzero state
		[[ "$state" != 0 ]] && break
	done


	# did the resolution succeed?
	if [[ "$i" == "${#keys[@]}" ]]; then
		# return length?
		if [[ "$state" == 3 ]]; then
			echo "${#obj[@]}"

		# all steps finished
		elif [[ "$j" == "$k"  ]]; then
			# real value?
			if [[ "$state" == 1 ]]; then
				echo "$value"
			# echo object keys
			else
				echo "${!obj[@]}"
			fi
		fi
	fi
}

# split dependency version information
version_split() {
	# local variables
	local tmp
	local out

	out=()

        IFS='()' read -a tmp <<< "$1"

        out+=("$(echo ${tmp[0]})")

        IFS=' ' read -a tmp <<< "${tmp[1]}"

        out+=("${tmp[0]}")
        out+=("${tmp[1]}")

	echo "${out[@]}"
}

# resolve an octave dependency into a package atom
# (this may resolve into sci-mathematics/octave[useflags...])
resolve_octave() {
	# local variables
	local useflags
	local package
	local atom
	local info

	# split package name
	info=($(version_split "$1"))

	# octave builtins
	for package in "${octave_builtin[@]}"; do
		[[ "${info[0]}" == "$package" ]] \
			&& return 0
	done

	# octave itself (is applied implicitly without version)
	if [[ "${info[0]}" == octave ]]; then
		atom="sci-mathematics/octave"

		# version present?
		[[ "${info[1]}" ]] && \
			atom="${info[1]}${atom}-${info[2]}"

		echo "$atom"
		return 0
	fi

	# check if package is external
	for package in $(_ packages); do
		if [[ "${info[0]}" == "$package" ]]; then
			atom="${category}/${package}"

			# version present?
			[[ "${info[1]}" ]] && \
				atom="${info[1]}${atom}-${info[2]}"

			echo "$atom"
			return 0
		fi
	done

	# resolve failed
	return 1
}

# repository scan (don't run in subshell)
repository_scan() {
	# local variables
	local line
	local name
	local pcat

	declare -ga repolist
	while read line; do
		# extract package name and category
		name="${line##*/}"
		line="${line%/*}"
		pcat="${line##*/}"

		# filter dotfiles
		[[ "$name" == .* ]] && continue

		# filter known non-categories/names
		[[ "$pcat" == "eclass" 
			|| "$pcat" == "metadata"
			|| "$name" == "metadata" ]] && continue

		# filter categories without one - (they don't exist)
		[[ "$pcat" != *-* ]] && continue

		# add to repolist
		repolist+=("${pcat}/${name}")

	# recurse all repositories (requires a depth of 3)
	done < <(find "$repositories" -mindepth 3 -maxdepth 3 -type d)
}

# (will be tried in this order)
python_globs=(dev-python)

# category globs for other library packages
# (will be tried in this order)
other_globs=(dev-libs dev-db sci-libs sci-\* \*-libs dev-python dev-\*)

# resolve system dependency into a package atom
resolve_system() {
	# local variables
	local package
	local globs
	local _name
	local atom
	local info
	local name
	local pcat
	local line
	local try
	local res
	local i
	local j

	# split package name
	info=($(version_split "$1"))

	# package names to try
	try=()

	# python packages need special handling
	if [[ "${info[0]}" =~ ^python[0-9]+-(.*)$ ]]; then
		# this has to be a python package
		globs=("${python_globs[@]}")

		# remove 'python*-' prefix
		try+=("${BASH_REMATCH[1]}")
	else
		globs=("${other_globs[@]}")

		# remove possible '-dev' suffix
		# (not used by gentoo packages)
		try+=("${info[0]%-dev}")

		# try with and without the lib prefix
		# (may be used by gentoo package)
		local a=$([[ "${try[0]}" == lib* ]]; echo $?)
		[[ "$a" == 0 ]] && try+=("${try[0]#lib}")
	fi

	# resolved package atoms
	res=()

	# try static rules
	for name in "${!static_rules[@]}"; do
		# try mutations of name
		for _name in "${try[@]}"; do
			[[ "$_name" == "$name"* ]] \
				&& res+=("${static_rules[$name]}")
		done
	done

	# scan repository if nothing was resolved statically
	if [[ "${#res[@]}" < 1 ]]; then
		# the package index is so large that converting
		# to string to use a for loop is pointlessly inefficient
		i=0; j="${#repolist[@]}"
		while [[ "$i" -lt "$j" ]]; do
			package="${repolist[$i]}"

			# extract package name and category
			name="${package#*/}"
			#pcat="${package%/*}"
			
			# try mutations of name
			for _name in "${try[@]}"; do
				#[[ "$_name" == "$name"*
				#	|| "$name" == "$_name"* ]] \
				#		&& res+=("$package")
				[[ "$name" == "$_name" ]] \
					&& res+=("$package")
			done

			i=$(($i + 1))
		done
	fi

	# resolve failed
	[[ "${#res[@]}" < 1 ]] && return 1

	# use first package by default
	atom="${res[0]}"

	# pick a package in these categories if possible
	for glob in "${globs[@]}"; do
		# because no goto
		local _break=0

		# try all resolved atoms
		for package in "${res[@]}"; do
			# extract package name and category
			#name="${package#*/}"
			pcat="${package%/*}"

			if [[ "$pcat" == $glob ]]; then
				atom="$package"
				_break=1
				break
			fi
		done

		[[ "$_break" > 0 ]] && break
	done

	# version present?
	[[ "${info[1]}" ]] && \
		atom="${info[1]}${atom}-${info[2]}"

	echo "$atom"
	return 0
}

split_atom() {
	# local variables
	local n
	local op
	local ver
	local tmp

	# array reference
	local -n out="$1"

	# version operator
	tmp="$2"
	if [[ "$2" =~ ^([=\<\>]+)(.*) ]]; then
		op="${BASH_REMATCH[1]}"
		tmp="${BASH_REMATCH[2]}"
	fi

	# package version
	# this regex is trash, because my bash
	# is apparently unable to use word boundaries
	if [[ "$tmp" =~ (^|[^[:alnum:]=\<\>~.])([0-9][0-9.-]*)$ ]]; then
		ver="${BASH_REMATCH[2]}"
	fi

	# package name
	if [[ "$ver" ]]; then 
		n=$((${#tmp} - ${#ver} - 1))
		[[ "$n" -lt 0 ]] \
			&& unset tmp \
			|| tmp="${tmp:0:$n}"
	fi

	out+=("$op")
	out+=("$tmp")
	out+=("$ver")
}

# comprare package versions
# $? == 0 -> both versions are equal
# $? == 1 -> version 1 is smaller than 2
# $? == 2 -> version 1 is bigger than 2
vercmp() {
	# local variables
	local a
	local b
	local n
	local r
	local i

	# split by subversion
	IFS=. read -a a <<< "$1"
	IFS=. read -a b <<< "$2"

	# loop through all subversions
	i=0
	while true; do
		# if either string overflows, break this loop
		[[ "$i" -ge "${#a[@]}" ]] && break
		[[ "$i" -ge "${#b[@]}" ]] && break

		# comparison
		[[ "${a[$i]}" -lt "${b[$i]}" ]] && return 1
		[[ "${a[$i]}" -gt "${b[$i]}" ]] && return 2

		i=$(($i + 1))
	done

	# for the possible remaining parts of the other string
	# check if any of the subversions is nonzero, this will
	# automatically mean it's larger given we haven't returned yet
	if [[ "$i" -lt "${#a[@]}" ]]; then
		local -n n=a
		r=2
	else
		local -n n=b
		r=1
	fi
	while [[ "$i" -lt "${#n[@]}" ]]; do
		[[ "${n[$i]}" -ne 0 ]] 2>/dev/null \
			&& return "$r"
		i=$(($i + 1))
	done

	return 0
}

# return the shortest of all arguments
shortest() {
	local out
	local arg

	out="$1"
	shift
	
	for arg in "$@"; do
		[[ "${#out}" -lt "${#arg}" ]] \
			&& out="$arg"
	done

	echo "$out"
}

# combine multiple atoms of the same package into
# the most specific one while considering versions
prune_atoms() {
	# local variables
	local op
	local out
	local key
	local val
	local atom
	local split

	# array reference
	local -n input="$1"

	# map package names to atom properties
	local -A map

	# process atoms
	for atom in "${input[@]}"; do
		# split atom
		split=()
		split_atom split "$atom"

		# expand result
		op="${split[0]}"
		key="${split[1]}"
		ver="${split[2]}"

		# stored value of format
		# [op]minversion,[op]maxversion
		# (either version can be omitted)
		IFS=, read -a val <<< "${map[$key]}"

		# store a zero minimum version initially
		# as that will compare greater to all others
		[[ "${#val[@]}" > 0 ]] || map["$key"]=">0,"

		# if the atom doesn't have a version, we stop here
		[[ "$ver" ]] || continue

		# if the version operator is missing, assume
		# the specified value is a minimum version.
		# we also treat a minimum version and exact
		# version the same.
		[[ "$op" || "$op" != \= ]] || op=">="

		# maximum version
		if [[ "$op" == \<* ]]; then
			# previous max version
			if [[ "${val[1]}" ]]; then
				# split version and operator
				split=()
				split_atom split "${val[1]}"

				# compare versions
				vercmp "$ver" "${split[2]}"
				case "$?" in
				# if versions are equal
				# use the stricter operator
				0) val[1]="$(shortest \
					"$op" "${split[2]}")${ver}";;

				# if new version is smaller
				# update the map to use it
				1) val[1]="${op}${ver}";;
				esac
			# just set this one
			else
				val[1]="${op}${ver}"
			fi

		# minimum version
		elif [[ "$op" == \>* ]]; then
			# previous min version
			if [[ "${val[0]}" ]]; then
				# split version and operator
				split=()
				split_atom split "${val[0]}"

				# compare versions
				vercmp "$ver" "${split[2]}"
				case "$?" in
				# if versions are equal
				# use the stricter operator
				0) val[0]="$(shortest \
					"$op" "${split[2]}")${ver}";;

				# if new version is smaller
				# update the map to use it
				2) val[0]="${op}${ver}";;
				esac

			# just set this one
			else
				val[0]="${op}${ver}"
			fi
		fi

		# update value
		map["$key"]="${val[0]},${val[1]}"
	done

	# construct output
	out=()
	for key in "${!map[@]}"; do
		# read stored value
		IFS=, read -a val <<< "${map[$key]}"

		# minimum version
		if [[ "${val[0]}" ]]; then
			# split version and operator
			split=()
			split_atom split "${val[0]}"

			# if version is zero, discard version
			# information from the package atom
			vercmp 0 "${split[2]}"
			[[ "$?" == 0 ]] \
				&& out+=("${key}") \
				|| out+=("${split[0]}${key}-${split[2]}")
		fi

		# maximum version
		if [[ "${val[1]}" ]]; then
			# split version and operator
			split=()
			split_atom split "${val[1]}"

			# add to output
			out+=("${split[0]}${key}-${split[2]}")
		fi
	done

	# return
	echo "${out[@]}"
}

# find known license(s) in the repositories
# that best match the input
find_license() {
	echo "$1"
}

# main function
main() {
	# local variables
	local n
	local tmp
	local atom
	local line
	local deps
	local value
	local query
	local where
	local index
	local fields
	local current
	local package

	local ver
	local url
	local icon
	local desc
	local label
	local license
	local home

	local target

	# package index
	local -A packages

	# retreive package index (packages are in order)
	echo "Retreiving package index... ($octave_index)"
	while read line; do
		# fields are quoted, so this splits them properly
		eval "fields=($line)"

		# first field is the package name
		package="${fields[0]}"

		# should we ignore this package
		[[ " ${ignore_packages[@]} " =~ " $package " ]] \
			&& continue

		# third field is the value to be assigned
		value="${fields[2]}"

		# progress output
		if [[ "$current" != "$package" ]]; then
			if [[ "$current" ]]; then
				[[ "$DEBUG" ]] && break
				n="$(_ packages "${current}.versions@")"
				echo -e "\b\b\bdone. (${n} version$( \
					[[ "$n" > 1 ]] && echo s))"
			fi
			echo -n "Package '${package}' ..."
			current="$package"
		fi

		# query starts with package name
		query="$package"

		# parse second filed into object query
		IFS=. read -a fields <<< "${fields[1]}"
		for part in "${fields[@]}"; do
			# split possible array index
			IFS='()' read -a part <<< "$part"
			where="${part[0]}"
			index="${part[1]}"

			# add to query
			# octave/matlab is 1 indexed, bash is zero indexed
			query="${query}.${where}"
			[[ "$index" ]] && query="${query}@$(($index - 1))"
		done

		# set object property to value
		object packages "$query" "$value"

	done < <(curl -s "$octave_index" | gawk "$gawk_program")
	
	# finalize progress output
	if [[ "$current" ]]; then
		n="$(_ packages "${current}.versions@")"
		echo -e "\b\b\bdone. (${n} version$( \
			[[ "$n" > 1 ]] && echo s))"
	fi
	echo "Total ${#packages[@]} packages."

	# cache repository packages
	echo -n "Caching repository index ..."
	repository_scan
	if [[ "${#repolist[@]}" > 0 ]]; then
		echo -e "\b\b\bdone. (${#repolist[@]} packages)" 
	else
		echo -e "\b\b\bfailed. (no packages found)"
		return 1
	fi

	echo "Initializing repository..."

	# add to /etc/portage/repos.conf/
	tmp="/etc/portage/repos.conf/octave.conf"
	if [[ -d "${tmp%/*}" ]]; then
		if [[ ! -f "$tmp" || $(md5sum "$tmp" \
			| cut -d\  -f1) != $(echo -n "$repo_conf" \
				| md5sum | cut -d\  -f1) ]]; then
			echo "Adding/modifying repository config..."
			echo -n "$repo_conf" > "$tmp"
			[[ "$?" != 0 ]] && echo "Failed, try running as root."
		fi
	fi

	# add category to /etc/portage/categories
	tmp="/etc/portage/categories"
	grep "^${category}\$" "$tmp" &>/dev/null
	if [[ "$?" != 0 ]]; then
		echo "Adding ${category} to ${tmp}..."
		echo "${category}" >> "$tmp"
		[[ "$?" != 0 ]] && echo "Failed, try running as root."
	fi

	# make sure directory structure is valid
	for dir in "${output}/"{"${category}",profiles,eclass,metadata}; do
		if [[ ! -d "$dir" ]]; then
			mkdir -p "$dir" || exit 1
		fi
	done

	# delete old packages
	while read package; do
		rm -rv "${package}"
	done < <(find "${output}/${category}" -mindepth 1 -maxdepth 1)

	# repository name
	tmp="${output}/profiles/repo_name"
	[[ ! -f "$tmp" ]] \
		&& echo octave > "$tmp"

	# create octave eclass
	tmp="${output}/eclass/octave.eclass.new"
	[[ ! -f "$tmp" || $(md5sum "$tmp" \
		| cut -d\  -f1) != $(echo -n "$octave_eclass" \
			| md5sum | cut -d\  -f1) ]] \
		&& echo -n "$octave_eclass" > "$tmp"
	
	# create layout.conf
	tmp="${output}/metadata/layout.conf"
	[[ ! -f "$tmp" || $(md5sum "$tmp" \
		| cut -d\  -f1) != $(echo -n "$layout_conf" \
			| md5sum | cut -d\  -f1) ]] \
		&& echo -n "$layout_conf" > "$tmp"

	# create ebuilds
	for package in $(_ packages); do
		n="$(_ packages "${package}.versions@")"
		echo "Processing package '${package}' (${n} version$( \
			[[ "$n" > 1 ]] && echo s))..."

		# per package data
		desc="$(_ packages "${package}.description")"
		for i in $(_ packages "${package}.links"); do
			# shorthand
			self="${package}.links@${i}"

			# relevant data
			url="$(_ packages "${self}.url")"
			icon="$(_ packages "${self}.icon")"
			label="$(_ packages "${self}.label")"

			# license
			if [[ "$icon" == *copyright* ]]; then
				license="$(find_license "$label")"

			# home
			elif [[ "$label" == repository ]]; then
				home="$url"
			fi
		done

		for i in $(_ packages "${package}.versions"); do
			# only consider latest version
			[[ "$latest_only" == 1 && "$i" -lt "$(($n - 1))" ]] \
				&& continue

			failed=0

			# shorthand
			self="${package}.versions@${i}"

			ver=$(_ packages "${self}.id")

			# convert dev to 9999
			[[ "$ver" == dev ]] && ver=9999

			# don't use dev versions if others are available
			if [[ "$latest_only" == 1 && "$ver" == 9999 ]]; then
				# decrementing should give a numeric version
				if [[ "$i" > 0 ]]; then
					i=$(($i - 1))
					self="${package}.versions@${i}"
					ver=$(_ packages "${self}.id")
				fi
			fi

			url=$(_ packages "${self}.url")

			echo " Version '$([[ "$ver" == 9999 ]] \
				&& echo dev || echo "$ver")'..."

			# resolve dependencies
			echo " Resolving dependencies..."
			deps=()

			# octave package dependencies + octave
			for j in $(_ packages "${self}.depends"); do
				# shorthand
				_self="${self}.depends@${j}"

				# get dependency
				dep="$(_ packages "${_self}.name")"

				# resolve dependency
				echo -n "  ${dep} ..."
				res=$(resolve_octave "$dep")
				if [[ $? == 0 ]]; then
					echo -ne "\b\b\b"
					if [[ "$res" ]]; then
						echo "-> ${res}"
						deps+=("${res}")
					else
						echo "-> (builtin)"
					fi
				else
					echo -e "\b\b\bfailed."
					failed=$(($failed + 1))
				fi
			done

			# system package dependencies
			unset system_key
			for key in $(_ packages "${self}"); do
				if [[ "$key" == ubuntu* ]]; then
					system_key="$key"
					break
				fi
			done
			if [[ "$system_key" ]]; then
				for j in $(_ packages "${self}.${system_key}"); do
					# shorthand
					_self="${self}.${system_key}@${j}"

					# get dependency
					dep="$(_ packages "${_self}.name")"

					# resolve dependency
					echo -n "  ${dep} ..."
					res=$(resolve_system "$dep")
					if [[ $? == 0 ]]; then
						echo -ne "\b\b\b"
						if [[ "$res" ]]; then
							echo "-> ${res}"
							deps+=("${res}")
						else
							echo "-> (none)"
						fi
					else
						echo -e "\b\b\bfailed."
						failed=$(($failed + 1))
					fi
				done
			fi

			# dependency resolution failure isn't a hard error
			# we just won't generate an ebuild for this package
			if [[ "$failed" > 0 ]]; then
				echo " Failed to resolve ${failed} dependenc$( \
					[[ "$failed" > 1 ]] && echo ies \
						|| echo y), skipping."
				continue
			fi

			# add extra hard coded dependencies
			for dep in "${extra_depends[$package]}"; do
				deps+=("$dep")
			done

			# prune dependencies
			deps=($(IFS=\n sort <<< $(prune_atoms deps)))
			tmp="${#deps[@]}"
			echo " Pruned (${tmp} atom$( \
				[[ "$tmp" > 1 ]] && echo s)):"
			for atom in "${deps[@]}"; do
				echo "  ${atom}"
			done

			# ebuild target
			target="${output}/${category}/${package}/${package}-${ver}.ebuild"

			echo -e " Generating ebuild at:\n  ${target}"

			# make sure dir exists
			tmp="${target%/*}"
			if [[ ! -d "$tmp" ]]; then
				mkdir -p "$tmp" || return 1
			fi

			# ebuild generation
			# (most functionality is in octave.eclass)
			echo "# Autogenerated by ${0} on $(date --rfc-email)" > "$target"
			echo -e "EAPI=8\n" >> "$target"
			echo -e "inherit octave\n" >> "$target"
			echo "DESCRIPTION=\"${desc}\"" >> "$target"
			echo "LICENSE=\"${license}\"" >> "$target"
			echo -e "HOMEPAGE=\"${home}\"\n" >> "$target"
			echo -e "SRC_URI=\"\n${url} -> \${P}.tar.gz\"" >> "$target"
			echo "RESTRICT=\"mirror\"" >> "$target"
			[[ "$ver" == 9999 ]] \
				&& echo -e "KEYWORDS=\"\"\n" >> "$target" \
				|| echo -e "KEYWORDS=\"~amd64 ~x86\"\n" >> "$target"
			echo -n "RDEPEND=\"" >> "$target"
			for atom in "${deps[@]}"; do
				echo -en "\n\t${atom}" >> "$target"
			done
			echo -e "\"\nDEPEND=\"\${RDEPEND}\"" >> "$target"
		done

		# generate metadata.xml for package
		tmp="${target%/*}/metadata.xml"
		echo "<!-- Autogenerated by ${0} on $(date --rfc-email) -->" > "$tmp"
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\">" >> "$tmp"
		echo "<!DOCTYPE pkgmetadata SYSTEM \"https://www.gentoo.org/dtd/metadata.dtd\">" >> "$tmp"
		echo "<pkgmetadata>" >> "$tmp"
		# nothing here at the moment
		echo "</pkgmetadata>" >> "$tmp"

		# generate manifest (for all ebuilds of this package)
		ebuild "$target" manifest
	done
}
main || exit 1
