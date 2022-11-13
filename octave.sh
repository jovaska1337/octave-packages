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
output="."

# ebuild category for generated ebuilds
category="octave-packages"

# "builtin" octave packages (these don't resolve as a dependency)
declare -A octave_builtin
# the pkg package manager is built into octave
octave_builtin[pkg]=""
# this isn't a package anymore but we can force USE=sundials
# to have all the ODE solvers available for use
octave_builtin[odepkg]="sci-mathematics/octave[sundials]"

# packages to ignore from the repository
# (these won't be added to the parsed index)
declare -a octave_ignore
# this is already built into octave
octave_ignore+=(pkg)
# as portage now handles the octave package
# management, I see no reason to include this
octave_ignore+=(packajoozle)
# example package, no need for an ebuild
octave_ignore+=(pkg-example)

# static translation rules for library names
# ('lib' prefix and '-dev' suffix removed)
declare -A static_rules
static_rules[avcodec]="media-video/ffmpeg"
static_rules[avformat]="media-video/ffmpeg"
static_rules[swscale]="media-video/ffmpeg"
static_rules[sqlite3]="dev-db/sqlite"
static_rules[zmq]="net-libs/zeromq"
static_rules[pq]="dev-db/postgresql"

# extra dependencies to add per package
declare -A extra_depends
# this is outright missing from the dependencies
extra_depends[fits]="sci-libs/cfitsio"
# symbolic is missing version information from the sympy
# dependency. doesn't work with >=sympy-1.6 at all
# (this is what you get when the devs use LTS distros)
extra_depends[symbolic]="<dev-python/sympy-1.6"
# force USE=opengl to pull in fltk
extra_depends[image-acquisition]="sci-mathematics/octave[opengl]"

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

# trim whitespace from input
trim() {
	local out
	out="$1"
	out="${out#"${out%%[![:space:]]*}"}"
	out="${out%"${out##*[![:space:]]}"}"
	echo "$out"
}

# does array contain value (check with nameref and
# indecies to avoid pointless string operations)
contains() {
	# reference value in parent scope
	local -n _array_="$1"

	# local variables
	local i
	local j

	# scan array
	i=0
	j="${#_array_[@]}"
	while [[ "$i" -lt "$j" ]]; do
		[[ "${_array_[$i]}" == "$2" ]] && return 0
		i=$(($i + 1))
	done

	# value is not in array
	return 1
}

# Lehvenstein distance
levdist() {
	# local variables
	local i
	local j
	local m
	local n
	local a
	local b
	local c
	local _vec0
	local _vec1
	local names
	local state

	# m & n are shorthands for input lengths
	m="${#1}"
	n="${#2}"

	# initialize work vectors
	_vec0=()
	_vec1=()
	names=(_vec0 _vec1)
	state=1
	local -n x=_vec0
	local -n y=_vec1
	i=0
	while [[ "$i" -le "$n" ]]; do
		x+=($i)
		y+=(0)
		i=$(($i + 1))
	done

	# algorithm
	i=0
	while [[ "$i" -lt "$m" ]]; do
		y[0]=$(($i + 1))

		j=0
		while [[ "$j" -lt "$n" ]]; do
			a=$((${x[$(($j + 1))]} + 1)) # deletion cost
			b=$((${y[$j]} + 1))          # insertion cost

			# substitution cost
			[[ "${1:$i:1}" == "${2:$j:1}" ]] \
				&& c=${x[$j]} || c=$((${x[$j]} + 1))

			# minimal cost (a = min(a, b, c))
			[[ $b -lt $a ]] && a=$b
			[[ $c -lt $a ]] && a=$c

			# set value for next loop
			y[$(($j + 1))]=$a

			j=$(($j + 1))
		done

		# swap vectors
		local -n x="${names[$state]}"
		state=$((! $state))
		local -n y="${names[$state]}"

		i=$(($i + 1))
	done

	# assume distance isn't greater than 255
	return ${x[-1]}
}

# longest common prefix length
lcprefix() {
	# local variables
	local i
	local m
	local n

	i=0; m="${#1}"; n="${#2}"
	while [[ "$i" -lt "$m" && "$i" -lt "$n" ]]; do
		[[ "${1:$i:1}" != "${2:$i:1}" ]] && break
		i=$(($i + 1))
	done

	echo "$i"
}

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

	# octave builtins (with optional dependency information)
	if [[ " ${!octave_builtin[@]} " =~ " ${info[0]} " ]]; then
		atom="${octave_builtin[${info[0]}]}"
		[[ "$atom" ]] && echo "$atom"
		return 0
	fi

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

	declare -ga repolist=()
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
	local _tmp
	local use

	# array reference
	local -n out="$1"

	# version operator
	_tmp="$2"
	if [[ "$2" =~ ^([=\<\>]+) ]]; then
		op="${BASH_REMATCH[1]}"
		n="${#op}"
		_tmp="${_tmp:$n}"
	fi

	# useflags
	if [[ "$_tmp" =~ \[([^\[]+)\]$ ]]; then
		use="${BASH_REMATCH[1]}"
		n=$((${#_tmp} - ${#use} - 2))
		_tmp="${_tmp:0:$n}"
	fi

	# package version
	# this regex is trash, because my bash
	# is apparently unable to use word boundaries
	if [[ "$_tmp" =~ (^|[^[:alnum:]=\<\>~.])([0-9][0-9.-]*)$ ]]; then
		ver="${BASH_REMATCH[2]}"
	fi

	# package name
	if [[ "$ver" ]]; then 
		n=$((${#_tmp} - ${#ver} - 1))
		[[ "$n" -lt 0 ]] \
			&& _tmp="" \
			|| _tmp="${_tmp:0:$n}"
	fi

	out+=("$op")
	out+=("$_tmp")
	out+=("$ver")

	IFS=, read -a use <<< "$use"
	for _tmp in "${use[@]}"; do
		IFS=' ' read -a _tmp <<< "$_tmp"
		out+=("${_tmp[0]}")
	done
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

# combine multiple atoms of the same package into the most
# specific one while considering versions and useflags
prune_atoms() {
	# local variables
	local op
	local out
	local key
	local use
	local tmp
	local _min
	local _max
	local _use
	local atom

	# array reference
	local -n input="$1"

	# map package names to atom properties
	local -A map

	# process atoms
	for atom in "${input[@]}"; do
		# split atom
		tmp=()
		split_atom tmp "$atom"

		# expand result
		op="${tmp[0]}"
		key="${tmp[1]}"
		ver="${tmp[2]}"
		use=("${tmp[@]:3}")

		# stored value is of format
		# [op]minversion;[op]maxversion;useflags
		# (any field may be omitted)
		IFS=\; read -a tmp <<< "${map[$key]}"
		_min="${tmp[0]}"
		_max="${tmp[1]}"
		_use="${tmp[2]}"
		IFS=, read -a _use <<< "$_use"

		# use hashmap keys for useflags
		# (more efficient than two nested for loops)
		local -A usemap=()
		for tmp in "${_use[@]}"; do
			usemap["$tmp"]=''
		done

		# add useflags
		for tmp in "${use[@]}"; do
			usemap["$tmp"]=''
		done

		# recombine to _use
		_use=''
		for tmp in "${!usemap[@]}"; do
			_use="${_use},${tmp}"
		done
		_use="${_use##,}"

		# store a zero minimum version initially
		# as that will compare greater to all others
		[[ "$_min" || "$_max" ]] || _min=">0"

		# if the atom doesn't have a version, we stop here
		if [[ ! "$ver" ]]; then
			map["$key"]="${_min};${_max};${_use}"
			continue
		fi

		# if the version operator is missing, assume
		# the specified value is a minimum version.
		# we also treat a minimum version and exact
		# version the same.
		[[ "$op" || "$op" != \= ]] || op=">="

		# maximum version
		if [[ "$op" == \<* ]]; then
			# previous max version
			if [[ "$_max" ]]; then
				# split version and operator
				tmp=()
				split_atom tmp "$_max"

				# compare versions
				vercmp "$ver" "${tmp[2]}"
				case "$?" in
				# if versions are equal
				# use the stricter operator
				0) _max="$(shortest \
					"$op" "${tmp[0]}")${ver}";;

				# if new version is smaller
				# update the map to use it
				1) _max="${op}${ver}";;
				esac
			# just set this one
			else
				_max="${op}${ver}"
			fi

		# minimum version
		elif [[ "$op" == \>* ]]; then
			# previous min version
			if [[ "$_min" ]]; then
				# split version and operator
				tmp=()
				split_atom tmp "$_min"

				# compare versions
				vercmp "$ver" "${tmp[2]}"
				case "$?" in
				# if versions are equal
				# use the stricter operator
				0) _min="$(shortest \
					"$op" "${tmp[0]}")${ver}";;

				# if new version is smaller
				# update the map to use it
				2) _min="${op}${ver}";;
				esac

			# just set this one
			else
				_min="${op}${ver}"
			fi
		fi

		# update value
		map["$key"]="${_min};${_max};${_use}"
	done

	# construct output
	out=()
	for key in "${!map[@]}"; do
		# read stored value
		IFS=\; read -a tmp <<< "${map[$key]}"
		_min="${tmp[0]}"
		_max="${tmp[1]}"
		_use="${tmp[2]}"

		# split version info
		tmp=()
		split_atom tmp "$_min"
		_min=("${tmp[@]}")
		tmp=()
		split_atom tmp "$_max"
		_max=("${tmp[@]}")

		# check if minimum version is 0
		vercmp 0 "${_min[2]}"
		tmp="$?"

		# minimum and maximum versions
		# (we could use the asterix postfix to
		# simplify this to a single atom in some
		# cases but it likely breaks others, thus
		# we will always output two atoms here)
		if [[ "$_min" && "$_max" && "$tmp" -ne 0 ]]; then
			# min version with useflags
			atom="${_min[0]}${key}-${_min[2]}"
			[[ "$_use" ]] && atom="${atom}[${_use}]"
			out+=("$atom")

			# max version
			atom="${_max[0]}${key}-${_max[2]}"
			out+=("$atom")

		# maximum version only
		elif [[ "${_max[2]}" ]]; then
			atom="${_max[0]}${key}-${_max[2]}"
			[[ "$_use" ]] && atom="${atom}[${_use}]"
			out+=("$atom")

		# minimum version only
		elif [[ "${_min[2]}" ]]; then
			# if version is zero, discard version
			# information from the package atom
			[[ "$tmp" == 0 ]] \
				&& atom="${key}" \
				|| atom="${_min[0]}${key}-${_min[2]}"

			[[ "$_use" ]] && atom="${atom}[${_use}]"
			out+=("$atom")

		# no versioning
		else
			atom="${key}"
			[[ "$_use" ]] && atom="${atom}[${_use}]"
			out+=("$atom")
		fi
	done

	# return
	echo "${out[@]}"
}

# scan repositories for licenses
license_scan() {
	# local variables
	local -A map

	# recurse through all license directories
	# in each repository (we use hashmap keys
	# in order to avoid duplicates in the list)
	while read dir; do
		while read license; do
			license="${license##*/}"
			map["$license"]=""
		done < <(find "$dir" -type f)
	done < <(find "${repositories}" -mindepth 2 \
		-maxdepth 2 -type d -name licenses)

	# this assignment does pointless string ops
	# but there isn't really a better way of doing it
	declare -ga licenses=("${!map[@]}")
}

# find known license(s) in the repositories
# that best match the input
find_license() {
	# local variables
	local i
	local j
	local x
	local y
	local z
	local tmp
	local part
	local parts
	local filtered

	# split by "and" (used by the octave repository
	# as a separator in the license field)
	part="${1}and" 
	parts=()
	while [[ "$part" ]]; do
		tmp="$(trim "${part%%and*}")"
		parts+=("${tmp// /-}")
		part="${part#*and}"
	done

	echo "${parts[@]}"

	# process each part
	# (this doesn't really work properly)
#	for part in "${parts[@]}"; do
#		# find licenses with at least 3
#		# character common prefix match
#		i=0; j="${#licenses[@]}"; filtered=()
#		while [[ "$i" -lt "$j" ]]; do
#			tmp="${licenses[$i]}"
#
#			# longest common prefix
#			[[ $(lcprefix "$part" "$tmp") -ge 4 ]] \
#				&& filtered+=("$tmp")
#
#			i=$(($i + 1))
#		done
#
#		# select license from the filter with the
#		# smallest lehvenstein distance
#		i=0; j="${#filtered}"; x=""; y=255
#		while [[ "$i" -lt "$j" ]]; do
#			tmp="${filtered[$i]}"
#			
#			# distance
#			levdist "$part" "$tmp"
#			z=$?
#
#			# keep track of best match
#			if [[ "$z" -lt "$y" ]]; then
#				x="$tmp"
#				y="$z"
#			fi
#
#			i=$(($i + 1))
#		done
#
#		echo "$part -> $x $y"
#	done
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
		contains octave_ignore "$package" && continue

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

	# cache available licenses
#	echo -n "Caching licenses ..."
#	license_scan
#	if [[ "${#licenses[@]}" > 0 ]]; then
#		echo -e "\b\b\bdone. (${#licenses[@]} licenses)"
#	else
#		# this isn't a hard error, we just fall back
#		# to setting LICENSE to whatever the index
#		# specifies directly
#		echo -e "\b\b\bfailed. (no licenses found)"
#	fi

	# add to /etc/portage/repos.conf/
#	tmp="/etc/portage/repos.conf/octave.conf"
#	if [[ -d "${tmp%/*}" ]]; then
#		if [[ ! -f "$tmp" || $(md5sum "$tmp" \
#			| cut -d\  -f1) != $(echo -n "$repo_conf" \
#				| md5sum | cut -d\  -f1) ]]; then
#			echo "Adding/modifying repository config..."
#			echo -n "$repo_conf" > "$tmp"
#			[[ "$?" != 0 ]] && echo "Failed, try running as root."
#		fi
#	fi

	# add category to /etc/portage/categories
#	tmp="/etc/portage/categories"
#	grep "^${category}\$" "$tmp" &>/dev/null
#	if [[ "$?" != 0 ]]; then
#		echo "Adding ${category} to ${tmp}..."
#		echo "${category}" >> "$tmp"
#		[[ "$?" != 0 ]] && echo "Failed, try running as root."
#	fi

	# make sure directory structure is valid
#	for dir in "${output}/"{"${category}",profiles,eclass,metadata}; do
#		if [[ ! -d "$dir" ]]; then
#			mkdir -p "$dir" || exit 1
#		fi
#	done

	# delete old packages
	echo "Removing old packages ..."
	while read package; do
		rm -r "${package}"
	done < <(find "${output}/${category}" -mindepth 1 -maxdepth 1 -type d)

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
			echo " Version '${ver}'..."

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

			# resolve dependencies (always depend on octave)
			echo " Resolving dependencies..."
			deps=( sci-mathematics/octave )

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
				[[ "$dep" ]] || continue
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
			echo -e "SRC_URI=\"\n\t${url} -> \${P}.tar.gz\"" >> "$target"
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
