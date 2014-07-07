#!/bin/bash

# The following options enable a kind of strict mode: exit script when a
# command fails, and fail when accessing undefined variables.
set -Eu
set -o pipefail

# Allow setting via environment, falling back to a default
readonly EXAMPLE=${EXAMPLE:-"default"}

readonly USAGE="USAGE:
$0 [<options>] [--] [<positional arg> ...]
$0 --help

A template for a Bash script. In the interest of readability, this makes no
attempt to be POSIX compliant, and therefore Bash-only syntax is used
liberally.

Options:
    --example, -x <val>  Sets the example variable to <val>.
                             DEFAULT: \"default\"
    --help, -h           Prints this usage information and exits.
"

function usage {
	echo "$USAGE"
}

# For convenience, you can pipe to STDERR for error output
function STDERR {
	cat >&2
}

# Set an error handler to log the location of an error before exiting
function _exit_err {
	local retval=$1
	STDERR <<< "ERROR: $BASH_SOURCE: line $BASH_LINENO: $BASH_COMMAND"
	exit $retval
}; trap '_exit_err $?' ERR

# Process options, filter out positional arguments
declare -a positional_args
while (( $# )); do
	case $1 in
		--help|-h)    usage; exit ;;
		--example|-x) example_opt="$2"; shift ;;
		--example=*)  example_opt=${1#*=} ;;
		--) # Remaining args are to be treated as positional
			shift
			# Consume the rest of the arguments
			while (( $# )); do positional_args+=("$1"); done
			;;
		-*) STDERR <<< "ERROR: Unrecognized option"; exit 1 ;;
		*) positional_args+=("$1") ;;
	esac
	shift
done
# Handle the positional arguments
if (( ${#positional_args[@]} > 0 )); then
	set -- "${positional_args[@]}"
	unset positional_args # Don't pollute the global namespace
fi

function main {
	# Use the value set by the options, falling back to the global variable
	local example_var=${example_opt:-$EXAMPLE}
	echo "Example var: $example_var"

	local i=0
	echo "Positional args:"
	for arg in "$@"; do
		i=$((i + 1))
		echo "    $i) $arg"
	done
}

main "$@"
