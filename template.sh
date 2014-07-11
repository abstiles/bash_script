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
function usage { echo "$USAGE"; }

# Logs message to stderr, then terminates with nonzero exit code
function error { printf "$1\n" "${@:2}" >&2; exit 1; }
# Log messages to stdout based on verbosity setting. Hidden by default.
function log {
	local level=1;
	if [[ $1 == -l ]]; then level=$(printf %d $2); shift 2; fi
	if (( $level <= ${verbosity:-0} )); then printf "$1\n" "${@:2}"; fi
}

# Set an error handler to log the location of an error before exiting
function _exit_err {
	local retval=$1
	echo "ERROR: $BASH_SOURCE: line $BASH_LINENO: $BASH_COMMAND" >&2
	exit $retval
}; trap '_exit_err $?' ERR

# Process options, filter out positional arguments
declare -a positional_args
arg_flags=x
while (( $# )); do
	case $1 in
		--help|-h)    usage; exit ;;
		--verbose|-v) verbosity=$(( ${verbosity:-0} + 1 )) ;;
		--verbosity)  verbosity=$(printf %d $2); shift ;;
		--example|-x) example_opt="$2"; shift ;;
		--) shift; break ;;
		# Handle GNU-style long options with arguments, e.g., "--example=value"
		--?*=*) set -- "${1%%=*}" "${1#*=}" "${@:2}"; continue ;;
		# Handle POSIX-style short option chaining, e.g., "-xvf"
		-[^-]?*) if [[ ${1:1:1} =~ [${arg_flags-}] ]]
		         then set -- "${1:0:2}" "${1:2}" "${@:2}"
		         else set -- "${1:0:2}" "-${1:2}" "${@:2}"
		         fi; continue ;;
		-?*) error "ERROR: Unrecognized option $1\n$(usage)" ;;
		*) positional_args+=("$1") ;;
	esac
	shift
done
# Handle the positional arguments
if (( ${#positional_args[@]} > 0 )); then
	set -- "${positional_args[@]}" "$@"
fi
# Don't pollute the global namespace; remove globals used in arg processing
unset arg_flags
unset positional_args

function main {
	# Use the value set by the options, falling back to the global variable
	local example=${example_opt-$EXAMPLE}
	log "Example var: %s" "'$example'"
	log "Verbosity: %4d" "${verbosity:=0}"
	log "Positional args:"
	local i; for (( i=1; i <= $#; ++i )); do log "%5d) %s" "$i" "${!i}"; done
}

main "$@"
