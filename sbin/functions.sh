#!/bin/bash

#
#I stole a lot of things from the gentoo /sbin/rc script
#

RC_GOT_FUNCTIONS="yes"

#
# Internal variables
#

# Dont output to stdout?
RC_QUIET_STDOUT="${RC_QUIET_STDOUT:-no}"
RC_VERBOSE="${RC_VERBOSE:-no}"

# Should we use color?
RC_NOCOLOR="${RC_NOCOLOR:-no}"
# Can the terminal handle endcols?
RC_ENDCOL="yes"

#
# Default values for rc system
#
RC_TTY_NUMBER="${RC_TTY_NUMBER:-11}"
RC_PARALLEL_STARTUP="${RC_PARALLEL_STARTUP:-no}"
RC_NET_STRICT_CHECKING="${RC_NET_STRICT_CHECKING:-no}"
RC_USE_FSTAB="${RC_USE_FSTAB:-no}"
RC_USE_CONFIG_PROFILE="${RC_USE_CONFIG_PROFILE:-yes}"
RC_FORCE_AUTO="${RC_FORCE_AUTO:-no}"
RC_DEVICES="${RC_DEVICES:-auto}"
RC_DOWN_INTERFACE="${RC_DOWN_INTERFACE:-yes}"
RC_VOLUME_ORDER="${RC_VOLUME_ORDER:-raid evms lvm dm}"

#
# Default values for e-message indentation and dots
#
RC_INDENTATION=''
RC_DEFAULT_INDENT=2
#RC_DOT_PATTERN=' .'
RC_DOT_PATTERN=''

# void esyslog(char* priority, char* tag, char* message)
#
#    use the system logger to log a message
#
esyslog() {
	local pri=
	local tag=

	pri="$1"
	tag="$2"
	shift 2
	[ -z "$*" ] && return 0

	/usr/bin/logger -p "${pri}" -t "${tag}" -- "$*"

	return 0
}

# void eindent(int num)
#
#    increase the indent used for e-commands.
#
eindent() {
	local i="$1"
	[ "$i" -gt 0 ] || i=$RC_DEFAULT_INDENT
	esetdent $(expr ${#RC_INDENTATION} + $i)
}

# void eoutdent(int num)
#
#    decrease the indent used for e-commands.
#
eoutdent() {
	local i="$1"
	[ "$i" -gt 0 ] || i=$RC_DEFAULT_INDENT
	esetdent $(expr ${#RC_INDENTATION} - $i)
}

# void esetdent(int num)
#
#    hard set the indent used for e-commands.
#    num defaults to 0
#
esetdent() {
	local i="$1"
	[ "$i" -lt 0 ] && i=0
	RC_INDENTATION=$(printf "%${i}s" '')
}

# void einfo(char* message)
#
#    show an informative message (with a newline)
#
einfo() {
	einfon "$*\n"
	LAST_E_CMD="einfo"
	return 0
}

# void einfon(char* message)
#
#    show an informative message (without a newline)
#
einfon() {
	[ "${RC_QUIET_STDOUT}" == "yes" ] && return 0
	[ "${RC_ENDCOL}" != "yes" ] && [ "${LAST_E_CMD}" == "ebegin" ] && echo
	echo -ne " ${GOOD}*${NORMAL} ${RC_INDENTATION}$*"
	LAST_E_CMD="einfon"
	return 0
}

# void ewarn(char* message)
#
#    show a warning message + log it
#
ewarn() {
	if [ "${RC_QUIET_STDOUT}" == "yes" ] ; then
		echo " $*"
	else
		[ "${RC_ENDCOL}" != "yes" ] && [ "${LAST_E_CMD}" == "ebegin" ] && echo
		echo -e " ${WARN}*${NORMAL} ${RC_INDENTATION}$*"
	fi

	local name="rc-scripts"
	[ "$0" != "/sbin/runscript.sh" ] && name="${0##*/}"
	# Log warnings to system log
	esyslog "daemon.warning" "${name}" "$*"

	LAST_E_CMD="ewarn"
	return 0
}

# void eerror(char* message)
#
#    show an error message + log it
#
eerror() {
	if [ "${RC_QUIET_STDOUT}" == "yes" ] ; then
		echo " $*" >/dev/stderr
	else
		[ "${RC_ENDCOL}" != "yes" ] && [ "${LAST_E_CMD}" == "ebegin" ] && echo
		echo -e " ${BAD}*${NORMAL} ${RC_INDENTATION}$*"
	fi

	local name="rc-scripts"
	[ "$0" != "/sbin/runscript.sh" ] && name="${0##*/}"
	# Log errors to system log
	esyslog "daemon.err" "${name}" "$*"

	LAST_E_CMD="eerror"
	return 0
}

# void ebegin(char* message)
#
#    show a message indicating the start of a process
#
ebegin() {
	local msg="$*"
	local dots
	local spaces="${RC_DOT_PATTERN//?/ }"

	[ "${RC_QUIET_STDOUT}" == "yes" ] && return 0

	if [ -n "${RC_DOT_PATTERN}" ] ; then
		dots="$(printf "%$(expr "$COLS" - 3 - "${#RC_INDENTATION}" - "${#msg}" - 7)s" '')"
		dots="${dots//${spaces}/${RC_DOT_PATTERN}}"
		msg="${msg}${dots}"
	else
		msg="${msg} ..."
	fi
	einfon "${msg}"
	[ "${RC_ENDCOL}" == "yes" ] && echo

	LAST_E_LEN="$(expr 3 + "${#RC_INDENTATION}" + "${#msg}" )"
	LAST_E_CMD="ebegin"
	return 0
}

# void _eend(int error, char *efunc, char* errstr)
#
#    indicate the completion of process, called from eend/ewend
#    if error, show errstr via efunc
#
#    This function is private to functions.sh.  Do not call it from a
#    script.
#
_eend() {
	local retval="${1:-0}"
	local efunc="${2:-eerror}"
	local msg
	shift 2

	if [ "${retval}" == "0" ] ; then
		[ "${RC_QUIET_STDOUT}" == "yes" ] && return 0
		msg="${BRACKET}[ ${GOOD}ok${BRACKET} ]${NORMAL}"
	else
		if [ -c /dev/null ] ; then
			rc_splash "stop" &>/dev/null &
		else
			rc_splash "stop" &
		fi
		if [ -n "$*" ] ; then
			${efunc} "$*"
		fi
		msg="${BRACKET}[ ${BAD}!!${BRACKET} ]${NORMAL}"
	fi

	if [ "${RC_ENDCOL}" == "yes" ] ; then
		echo -e "${ENDCOL}  ${msg}"
	else
		[ "${LAST_E_CMD}" == ebegin ] || LAST_E_LEN=0
		printf "%$(expr "$COLS" - "$LAST_E_LEN" - 6 )s%b\n" '' "${msg}"
	fi

	return ${retval}
}

# void eend(int error, char* errstr)
#
#    indicate the completion of process
#    if error, show errstr via eerror
#
eend() {
	local retval="${1:-0}"
	shift

	_eend "${retval}" eerror "$*"

	LAST_E_CMD="eend"
	return ${retval}
}

# void ewend(int error, char* errstr)
#
#    indicate the completion of process
#    if error, show errstr via ewarn
#
ewend() {
	local retval="${1:-0}"
	shift

	_eend "${retval}" ewarn "$*"

	LAST_E_CMD="ewend"
	return ${retval}
}

# v-e-commands honor RC_VERBOSE which defaults to no.
# The condition is negated so the return value will be zero.
veinfo()  { [ "${RC_VERBOSE}" != "yes" ] || einfo "$@";  }
veinfon() { [ "${RC_VERBOSE}" != "yes" ] || einfon "$@"; }
vewarn()  { [ "${RC_VERBOSE}" != "yes" ] || ewarn "$@";  }
veerror() { [ "${RC_VERBOSE}" != "yes" ] || eerror "$@"; }
vebegin() { [ "${RC_VERBOSE}" != "yes" ] || ebegin "$@"; }
veend() {
	[ "${RC_VERBOSE}" == "yes" ] && { eend "$@"; return $?; }
	return ${1:-0}
}
vewend() {
	[ "${RC_VERBOSE}" == "yes" ] && { ewend "$@"; return $?; }
	return ${1:-0}
}

#
# Is a dir mounted
#
ismounted() {
	local dir="$1"
	local line
	[ -n "$dir" ] && [ -d "$dir" ] || return 1
	ifs="$IFS"
	IFS="
"
	for line in $(cat /proc/mounts)
	do
		IFS="$ifs"
		set -- $line
		[ "$dir" == "$2" ] && return 0
	done
	IFS="$ifs"
	return 1
}

##############################################################################
#                                                                            #
# This should be the last code in here, please add all functions above!!     #
#                                                                            #
# *** START LAST CODE ***                                                    #
#                                                                            #
##############################################################################

# Cache the CONSOLETYPE - this is important as backgrounded shells don't
# have a TTY. rc unsets it at the end of running so it shouldn't hang
# around
if [[ -z ${CONSOLETYPE} ]] ; then
	export CONSOLETYPE="$( /sbin/consoletype 2>/dev/null )"
fi
if [[ ${CONSOLETYPE} == "serial" ]] ; then
	RC_NOCOLOR="yes"
	RC_ENDCOL="no"
fi


for arg in "$@" ; do
	case "${arg}" in
		# Lastly check if the user disabled it with --nocolor argument
		--nocolor|-nc)
			RC_NOCOLOR="yes"
			RC_ENDCOL="no"
			;;
	esac
done

COLS="${COLUMNS:-0}"            # bash's internal COLUMNS variable
[ "$COLS" == 0 ]  && COLS="$(set -- $(/bin/stty size 2>/dev/null) ; echo "${2:-0}")"
[ "$COLS" -gt 0 ] || COLS=80       # width of [ ok ] == 7

if [[ ${RC_ENDCOL} == "yes" ]] ; then
	ENDCOL="\033[A\033[$(expr "$COLS" - 8)C"
else
	ENDCOL=''
fi


# Setup the colors so our messages all look pretty
if [[ ${RC_NOCOLOR} == "yes" ]] ; then
	unset GOOD WARN BAD NORMAL HILITE BRACKET
else
	GOOD='\033[1;32m'
	WARN='\033[1;33m'
	BAD='\033[1;31m'
	HILITE='\033[1;36m'
	BRACKET='\033[1;34m'
	NORMAL='\033[0m'
fi

##############################################################################
#                                                                            #
# *** END LAST CODE ***                                                      #
#                                                                            #
# This should be the last code in here, please add all functions above!!     #
#                                                                            #
##############################################################################

