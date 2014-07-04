################################################################################################################
##
## The functions in this section were borrowed from https://github.com/KyleJHarper/stupidbashtard
##
#################################################################################################################
function core_getopts {
  #@Description Largely backward compatible replacement for the built-in getopts routine in Bash. It allows long options, that's the only major change. Long and short options can use a-z A-Z and 0-9 (and hyphens for long opts, but long opt names cannot start or end with a hyphen). Long options are comma separated. Adding a colon after an option (but before the comma) implies an argument should follow; same as the built-in getopts.
  #@Description -
  #@Description We will use positional numeric parameters because BASH_ARGV only exists when extdebug is on and it pushes/pops up to $9. Positionals go up to ${10}+ if you use braces for proper interpolation. Additional non-option arguments are stored in __SBT_NONOPT_ARGS to make life easier. You're welcome.
  #@Description -
  #@Description This function breaks the typical naming convention (upper/proper-casing latter segement of function name) on purpose. It makes it more in line with the internal getopts naming convention, plus it makes scanning with Docker easier.
  #@Description -
  #@Description A note about the OPTIND global. Bash uses this and so do we. But we have added a niceness feature. This is it:
  #@Description SBT's getopts will set OPTIND back to default when we're done. The normal getopts doesn't do this niceness. I deviate here because the only time it'll conflict is if a getopts case statement in a caller hits a function which does its own getopts. BUT!!! For this to work in normal bash getopts, you need: local OPTIND=1 anyway. So we fix add one niceness without affecting anticipated logic.

  #@Date 2013.07.13
  #@Usage core_getopts <'short options'> <'return_variable_name'> <'long options'> <"$@">

  #@$1 The list short options, same format as bash built-in getopts.
  #@$2 Textual name of the variable to send back to the caller, same as built-in getopts.
  #@$3 A list of the allowed long options. Even if it's blank, it must be passed: "" or ''
  #@$4 The arguments sent to the caller and now passed to us. It should always be passed quoted, like so: "$@" (NOT "$*").
  #@$4 You must use the 'at' symbol, not asterisk. Otherwise the positionals will be merged into a single word.

  # Invocation and preflight checks.
  core_LogVerbose 'Entering function.'
  if [ -z "${2}" ] || [ -z "${1}" ] ; then core_LogError "Invalid invocation of core_getopts." ; return 1 ; fi
if [ -z "${4}" ] ; then core_LogVerbose "No positionals were sent, odd. Not an error, but aborting." ; return 1 ; fi

  # Clean out OPTARG and setup variables
  core_LogVerbose 'Setting up variables.'
  OPTARG=''
  local _OPT='' #@$ Holds the positional argument based on OPTIND.
  local _temp_opt #@$ Used for parsing against _OPT to find a match.
  local -i _i #@$ Loop control, that's it.
  local -i _MY_OPTIND #@$ Holds the correctly offset OPTIND for grabbing arguments (because this function shifts 1, 2, and 3 for control).

  # If we're on the first index, turn off OPTERR if our prescribed opts start with a colon.
  core_LogVerbose 'Checking to see if OPTIND is 1 so we can reset items.'
  if [ ${OPTIND} -eq 1 ] ; then
core_LogVerbose 'OPTIND is 1. Resetting OPTERR.'
    OPTERR=1
    if [ "${1:0:1}" == ':' ] || [ "${3:0:1}" == ':' ] ; then
core_LogVerbose 'Error handling overriden, to be handled by caller. OPTERR disabled.'
      OPTERR=0
    fi
fi

core_LogVerbose 'Starting loop to find the option sent.'
  while true ; do
    # If the item was a non-switch item (__SBT_NONOPT_ARGS), we will loop multiple times. Ergo, reset vars here.
    core_LogVerbose "Clearing variables for loop with OPTIND of ${OPTIND}"
    _OPT=''
    _temp_opt=''
    _MY_OPTIND=${OPTIND}
    let _MY_OPTIND+=3
    let OPTIND++

    # Try to store positional argument in _OPT. If the option we tried to store in _OPT is blank, we're done.
    core_LogVerbose 'Assigning value to _OPT and leaving if blank.'
    eval _OPT="\"\${${_MY_OPTIND}}\""
    if [ -z "${_OPT}" ] ; then OPTIND=1 ; return 1 ; fi

    # If the _OPT has an equal sign, we need to place the right-hand contents in value and trim _OPT.
    if [[ "${_OPT}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*= ]] || [[ "${_OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9-]*= ]] ; then
core_LogVerbose 'Option specified has a value via assignment operator (=). Setting OPTARG and re-setting _OPT.'
      OPTARG="${_OPT##*=}"
      _OPT="${_OPT%%=*}"
    fi

    # If _OPT is a short opt with muliple switches at once, read/modify the __SBT_SHORT_OPTIND and _OPT.
    # Also need to decrement OPTIND if we're on the last item in the compact list.
    if [[ "${_OPT}" =~ ^-[a-zA-Z0-9][a-zA-Z0-9]+ ]] ; then
core_LogVerbose "Option is short and compacted (-abc...). Getting new _OPT with short index of ${__SBT_SHORT_OPTIND}"
      if [ -z "${_OPT:${__SBT_SHORT_OPTIND}:1}" ] ; then
core_LogVerbose "Current SHORT_OPTIND makes empty string, no more compact options in this OPTIND. Setting SHORT_OPTIND to 1 and returning 0 for next OPTIND."
        __SBT_SHORT_OPTIND=1
        return 0
      fi
core_LogVerbose "Assigning '-${_OPT:${__SBT_SHORT_OPTIND}:1}' to _OPT and incrementing SHORT_OPTIND for next run."
      _OPT="-${_OPT:${__SBT_SHORT_OPTIND}:1}"
      let __SBT_SHORT_OPTIND++
      core_LogVerbose "Substring based on SHORT_OPTIND was not blank, decrementing OPTIND for next run."
      let OPTIND--
    fi

    ##############################################
    # Try to match _OPT against a long option. #
    ##############################################
    if [ "${_OPT:0:2}" == '--' ] ; then
core_LogVerbose 'Option is long format. Processing as such.'
      _OPT="${_OPT:2}"
      if [ ${#_OPT} -lt 1 ] ; then
core_LogError "Long option attempted (--) but no name found."
        return 1
      fi
core_LogVerbose "Searching available options for option specified: ${_OPT}"
      for _temp_opt in ${3//,/ } ; do
        [ "${_temp_opt:0:1}" = ':' ] && _temp_opt="${_temp_opt:1}"
        if [ "${_temp_opt%:}" = "${_OPT}" ] ; then
core_LogVerbose "Found a matching option. Assigning to: $2"
          eval $2="\"${_temp_opt%:}\""
          if [ "${_temp_opt: -1}" == ':' ] && [ -z "${OPTARG}" ] ; then
core_LogVerbose "Option sent (${_OPT}) requires an argument; gathering now."
            let OPTIND++
            let _MY_OPTIND++
            eval OPTARG="\"\${${_MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
core_LogError "Option specified (--${_OPT}) requires a value."
              return 1
            fi
fi
core_LogVerbose "Successfully captured a long option. Leaving returning 0."
          return 0
        fi
done
      # No options were found in the allowed list. Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
core_LogError "Invalid argument: --${_OPT}"
        return 1
      fi
      # If we're not handling errors internally. Return success and let the user handle it. Set OPTARG too because bash does... odd.
      core_LogVerbose "Found an option that isn't in the list but I was told to shut up about it: --${_OPT}"
      eval $2="\"${_OPT}\""
      eval OPTARG="\"${_OPT}\""
      return 0
    fi

    ##############################################
    # Try to match _OPT against a short option #
    ##############################################
    if [ "${_OPT:0:1}" == '-' ] ; then
core_LogVerbose 'Option is short format. Processing as such.'
      _OPT="${_OPT:1}"
      if [ ${#_OPT} -lt 1 ] ; then
core_LogError "Short option attempted (-) but no name found."
        return 1
      fi
core_LogVerbose "Searching available options for option specified: ${_OPT}"
      _i=0
      while [ ${_i} -lt ${#1} ] ; do
core_LogVerbose "Checking item ${_i} with value of: ${1:${_i}:1}"
        _temp_opt="${1:${_i}:1}"
        if [ "${_temp_opt}" = "${_OPT}" ] ; then
core_LogVerbose "Found a matching option. Assigning to: $2"
          eval $2="\"${_temp_opt}\""
          let _i++
          if [ "${1:${_i}:1}" == ':' ] && [ -z "${OPTARG}" ] ; then
core_LogVerbose "Option sent (${_OPT}) requires an argument; gathering now. Also resetting SHORT OPTIND, as it must be the end."
            __SBT_SHORT_OPTIND=1
            let OPTIND++
            let _MY_OPTIND++
            eval OPTARG="\"\${${_MY_OPTIND}}\""
            if [ ${OPTERR} -ne 0 ] && [ -z "${OPTARG}" ] ; then
core_LogError "Option specified (-${_OPT}) requires a value."
              return 1
            fi
fi
core_LogVerbose "Successfully captured a short option. Leaving returning 0."
          return 0
        fi
let _i++
      done
      # No options were found in the allowed list. Send a warning, if necessary, and return failure.
      if [ ${OPTERR} -ne 0 ] ; then
core_LogError "Invalid argument: -${_OPT}"
        return 1
      fi
      # If we're not handling errors internally. Return success and let the user handle it. Set OPTARG too because bash does... odd.
      core_LogVerbose "Found an option that isn't in the list but I was told to shut up about it: -${_OPT}"
      eval $2="\"${_OPT}\""
      eval OPTARG="\"${_OPT}\""
      return 0
    fi

    # If we're here, then the positional item exists, is non-blank, and is not an option.
    # This means it's a non-option param (file, etc) and we need to keep processing.
    core_LogVerbose 'Argument sent not actually an option, storing in __SBT_NONOPT_ARGS array and moving to next positional argument.'
    __SBT_NONOPT_ARGS+=( "${_OPT}" )
  done
return 1 # This should never be reached
}

function core_LogError {
  #@Description Mostly for internal use. Sends info to std err if warnings are enabled. No calls to other SBT functions allowed to prevent infinite loops.
  #@Date 2013.07.14
  #@Usage core_LogError [-e] [-n] <'text to send' [...]>

  # Check for __SBT_WARNING first.
  ${__SBT_WARNING} || return 1

  while true ; do
if [ "${1:0:1}" == '-' ] ; then switches+=" ${1}" ; shift ; continue ; fi
break
done
echo ${switches} "(error in ${FUNCNAME[1]}: line ${BASH_LINENO[0]}) $@" >&2
  return 0
}


function core_LogVerbose {
  #@Description Mostly for internal use. Sends info to std err if verbosity is enabled. No calls to other SBT functions allowed to prevent infinite loops.
  #@Date 2013.07.14
  #@Usage core_LogVerbose [-e] [-n] <'text to send' [...]>

  # Check for __SBT_VERBOSE first. Save a lot of time if verbosity isn't enabled.
  ${__SBT_VERBOSE} || return 1

  # Setup variables
  local _switches='' #@$ Keep track of the switches to send to echo. This function accepts them the same as echo builtin does. Sorry printf
  local -i _spaces=$(( (${#FUNCNAME[@]} - 2) * 2)) #@$ Track the number of spaces to send

  while true ; do
if [ "${1:0:1}" == '-' ] ; then _switches+=" ${1}" ; shift ; continue ; fi
break
done

printf "%${_spaces}s" >&2
  echo ${_switches} "(${FUNCNAME[1]}: ${BASH_LINENO[0]}) $@" >&2
  return 0
}

#########################
##
## End code from SBT
##
#########################
