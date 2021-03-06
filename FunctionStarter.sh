#!/bin/bash

function usage()
{
cat << _EOT_

 FunctionStarter
-------------------- author: xshoji

This script generates a template of bash function.

Usage:
  ./$(basename "$0") --naming scriptName [ --description Description --required paramName,sample,description --optional paramName,sample,description,defaultValue(omittable) --flag flagName,description ]

Required:
  -n, --naming scriptName : Script name.

Optional:
  -d, --description Description                                       : Description of this script. [ example: --description "ScriptStarter's description here." ]
  -r, --required paramName,sample,description                         : Required parameter setting. [ example: --required id,1001,"Primary id here." ]
  -o, --optional paramName,sample,description,defaultValue(omittable) : Optional parameter setting. [ example: --option name,xshoji,"User name here.",defaultUser ]
  -f, --flag flagName,description                                     : Optional flag parameter setting. [ example: --flag dryRun,"Dry run mode." ]
  --debug : Enable debug mode

_EOT_
  [[ "${1+x}" != "" ]] && { exit "${1}"; }
  exit 1
}
function printColored() { local B="\033[0;"; local C=""; case "${1}" in "red") C="31m";; "green") C="32m";; "yellow") C="33m";; "blue") C="34m";; esac; printf "%b%b\033[0m" "${B}${C}" "${2}"; }



# Parse parameters
ARGS_REQUIRED=()
ARGS_OPTIONAL=()
ARGS_FLAG=()
ARGS_DESCRIPTION=()

for ARG in "$@"
do
    SHIFT="true"
    { [[ "${ARG}" == "--debug" ]]; } && { shift 1; set -eux; SHIFT="false"; }
    { [[ "${ARG}" == "--naming" ]] || [[ "${ARG}" == "-n" ]]; } && { shift 1; NAMING="${1}"; SHIFT="false"; }
    { [[ "${ARG}" == "--required" ]]    || [[ "${ARG}" == "-r" ]]; } && { shift 1; ARGS_REQUIRED+=("${1}"); SHIFT="false"; }
    { [[ "${ARG}" == "--optional" ]]    || [[ "${ARG}" == "-o" ]]; } && { shift 1; ARGS_OPTIONAL+=("${1}"); SHIFT="false"; }
    { [[ "${ARG}" == "--flag" ]]        || [[ "${ARG}" == "-f" ]]; } && { shift 1; ARGS_FLAG+=("${1}"); SHIFT="false"; }
    { [[ "${ARG}" == "--description" ]] || [[ "${ARG}" == "-d" ]]; } && { shift 1; ARGS_DESCRIPTION+=("${1}"); SHIFT="false"; }
    { [[ "${SHIFT}" == "true" ]] && [[ "$#" -gt 0 ]]; } && { shift 1; }
done
[[ -n "${HELP+x}" ]] && { usage 0; }
# Check required parameters
[[ -z "${NAMING+x}" ]] && { printColored yellow "[!] --naming is required.\n"; INVALID_STATE="true"; }
# Check invalid state and display usage
[[ -n "${INVALID_STATE+x}" ]] && { usage; }
# Initialize optional variables
[[ -z "${DESCRIPTION+x}" ]] && { DESCRIPTION=""; }



FUNCTION_NAME="${NAMING}"

# Define constant variable
PROVISIONAL_STRING=$(openssl rand -hex 12 | fold -w 12 | head -1)

#==========================================
# Functions
#==========================================


function parseValue() {
  echo "${1}" |sed "s/\\\,/${PROVISIONAL_STRING}/g" |awk -F',' '{print $'"${2}"'}' |sed "s/${PROVISIONAL_STRING}/,/g"
}

function toVarName() {
  local PARAM_NAME="${1}"
  echo "${PARAM_NAME}" | perl -pe 's/(?:^|_|-)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}'
}

function printFunctionDocumentBase() {

    echo "#######################################"
    local HAS_DESCRIPTION=""
    for ARG in "$@"
    do
      HAS_DESCRIPTION="true"
      echo "# ${ARG}"
    done
    [ "${HAS_DESCRIPTION}" == "true" ] && { echo "#"; }
    echo "# Usage:"

}



function printUsageExecutionExample() {
    local PARAM_NAME
    local SAMPLE
    # Add required parameters
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        SAMPLE=$(parseValue "${1}" 2)
        echo -n ' '"--"${PARAM_NAME}" ${SAMPLE}"
        shift 1
    done
}



function printUsageExecutionExampleFlag() {
    local PARAM_NAME
    # Add required parameters
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        echo -n ' '"--"${PARAM_NAME}""
        shift 1
    done
}




function printParameterDescription() {
    local PARAM_NAME
    local SAMPLE
    local DESCRIPTION
    local PARAM_NAME_SHORT
    local IS_USED_SHORT_PARAM
    for ARG in "$@"
    do
        # - [csv - Printing column separated by comma using Awk command line - Stack Overflow](https://stackoverflow.com/questions/26842504/printing-column-separated-by-comma-using-awk-command-line)
        PARAM_NAME=$(parseValue "${1}" 1)
        SAMPLE=$(parseValue "${1}" 2)
        DESCRIPTION=$(parseValue "${1}" 3)
        PARAM_NAME_SHORT=$(cut -c 1 <<<"${PARAM_NAME}")
        [ "${SAMPLE}" == "" ] && { SAMPLE="${PARAM_NAME}"; }
        [ "${DESCRIPTION}" == "" ] && { DESCRIPTION="${SAMPLE} means "${PARAM_NAME}"."; }
        IS_USED_SHORT_PARAM=$(grep "${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        echo -n "#   --"${PARAM_NAME}""
        # if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
        #     ARGS_SHORT+=("${PARAM_NAME_SHORT}")
        #     echo -n ",-${PARAM_NAME_SHORT}"
        # fi
        echo " ${SAMPLE} : ${DESCRIPTION}"
        shift 1
    done
}



function printParameterDescriptionFlag() {
    local PARAM_NAME
    local PARAM_NAME_SHORT
    local DESCRIPTION
    local IS_USED_SHORT_PARAM
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        PARAM_NAME_SHORT=$(parseValue "${1}" 2)
        DESCRIPTION=$(parseValue "${1}" 3)
        [ "${DESCRIPTION}" == "" ] && { DESCRIPTION="Enable "${PARAM_NAME}" flag."; }
        IS_USED_SHORT_PARAM=$(grep "${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        echo -n "#   --"${PARAM_NAME}""
        # if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
        #     ARGS_SHORT+=("${PARAM_NAME_SHORT}")
        #     echo -n ",-${PARAM_NAME_SHORT}"
        # fi
        echo " : ${DESCRIPTION}"
        shift 1
    done
}



function printFunctionDocumentBottomPart() {
    echo "#######################################"
}

function printFunctionTopPart() {
    echo "function ${1}() {"
}

function printLocalDeclarationArgument() {
    local PARAM_NAME
    local VAR_NAME
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        echo -n '    local '"${VAR_NAME}"'="";'
        shift 1
    done
}

function printParseArgument() {
    local PARAM_NAME
    local PARAM_NAME_SHORT
    local VAR_NAME
    local CONDITION
    local IS_USED_SHORT_PARAM=$(grep "1${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        PARAM_NAME_SHORT=$(cut -c 1 <<<${1})
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        CONDITION='[ "${_ARG}" == "--'""${PARAM_NAME}""'" ]'
        IS_USED_SHORT_PARAM=$(grep "1${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        # if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
        #     ARGS_SHORT+=("1${PARAM_NAME_SHORT}")
        #     CONDITION='('"${CONDITION}"' || [ "${_ARG}" == "-'"${PARAM_NAME_SHORT}"'" ])'
        # fi
        echo -n "${CONDITION}"' && { shift 1; '"${VAR_NAME}"'="${1}"; _SHIFT="false"; }; '
        shift 1
    done
}


function printParseArgumentFlag() {
    local PARAM_NAME
    local PARAM_NAME_SHORT
    local VAR_NAME
    local CONDITION
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        PARAM_NAME_SHORT=$(cut -c 1 <<<${1})
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        CONDITION='[ "${_ARG}" == "--'""${PARAM_NAME}""'" ]'
        IS_USED_SHORT_PARAM=$(grep "1${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        # if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
        #     ARGS_SHORT+=("1${PARAM_NAME_SHORT}")
        #     CONDITION='('"${CONDITION}"' || [ "${_ARG}" == "-'"${PARAM_NAME_SHORT}"'" ])'
        # fi
        echo -n "${CONDITION}"' && { shift 1; '"${VAR_NAME}"'="true"; _SHIFT="false"; }; '
        shift 1
    done
}



function printCheckRequiredArgument() {
    local PARAM_NAME
    local VAR_NAME
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        echo '    [ "${'"${VAR_NAME}"'}" == "" ] && { echo "[!] '${FUNCTION_NAME}'() requires --'""${PARAM_NAME}""' "; _INVALID_STATE="true"; }'
        shift 1
    done
}


function printVariableRequired() {
    local PARAM_NAME
    local VAR_NAME
    echo '    echo "  Required arguments"'
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        echo '    echo "    - '""${PARAM_NAME}""': ${'"${VAR_NAME}"'}"'
        shift 1
    done
}

function printVariableOptional() {
    local PARAM_NAME
    local VAR_NAME
    echo '    echo "  Optional arguments"'
    for ARG in "$@"
    do
        PARAM_NAME=$(parseValue "${1}" 1)
        VAR_NAME=$(toVarName "${PARAM_NAME}")
        echo '    echo "    - '""${PARAM_NAME}""': ${'"${VAR_NAME}"'}"'
        shift 1
    done
}






#==========================================
# Main
#==========================================
HAS_REQUIRED="false"
HAS_OPTION="false"
HAS_FLAG="false"
HAS_OPTION_OR_FLAG="false"
[[ ${#ARGS_REQUIRED[@]} -gt 0 ]] && { HAS_REQUIRED="true"; }
[[ ${#ARGS_OPTIONAL[@]} -gt 0 ]] && { HAS_OPTION="true"; }
[[ ${#ARGS_FLAG[@]} -gt 0 ]] && { HAS_FLAG="true"; }
{ [[ "${HAS_OPTION}" == "true" ]] || [[ "${HAS_FLAG}" == "true" ]]; } && { HAS_OPTION_OR_FLAG="true"; }


# Print usage example
printFunctionDocumentBase ${ARGS_DESCRIPTION[@]+"${ARGS_DESCRIPTION[@]}"}
echo -n "#   ${FUNCTION_NAME}"

# - [Bash empty array expansion with `set -u` - Stack Overflow](https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u)
printUsageExecutionExample ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}

[[ "${HAS_OPTION_OR_FLAG}" == "true" ]] && { echo -n " ["; }

printUsageExecutionExample ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printUsageExecutionExampleFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}

[[ "${HAS_OPTION_OR_FLAG}" == "true" ]] && { echo -n " ]"; }

echo ""
echo "# "

if [[ "${HAS_REQUIRED}" == "true" ]]; then
    echo "# Required arguments:"
    printParameterDescription "${ARGS_REQUIRED[@]}"
    echo "# "
fi

echo "# Optional arguments:"
if [[ "${HAS_OPTION_OR_FLAG}" == "true" ]]; then
    printParameterDescription ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
    printParameterDescriptionFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}
fi

printFunctionDocumentBottomPart


printFunctionTopPart "${FUNCTION_NAME}"

cat << "__EOT__"
    # Argument parsing
    local _ARG=""; local _SHIFT=""; local _INVALID_STATE=""
__EOT__

printLocalDeclarationArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}
printLocalDeclarationArgument ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printLocalDeclarationArgument ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}
echo

echo -n "    for _ARG in \"\$@\"; do local _SHIFT=\"true\"; "

printParseArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}
printParseArgument ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printParseArgumentFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}

echo "([ \"\${_SHIFT}\" == \"true\" ] && [ \"\$#\" -gt 0 ]) && { shift 1; }; done"


[[ "${HAS_REQUIRED}" == "true" ]] && { echo "    # Check required arguments"; }
printCheckRequiredArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}

# Check invalid state
echo "    # Check invalid state"
echo "    [ \"\${_INVALID_STATE}\" == \"true\" ] && { exit 1; }"
echo "    "
echo "    # Main"


if [[ "${HAS_REQUIRED}" == "true" || "${HAS_OPTION_OR_FLAG}" == "true" ]] ; then
    echo '    echo ""'
    echo '    echo "'${FUNCTION_NAME}'()"'
    REQUIRED_EOT="true"
fi

if [[ "${HAS_REQUIRED}" == "true" ]]; then
    printVariableRequired "${ARGS_REQUIRED[@]}"
fi
if [[ "${HAS_OPTION_OR_FLAG}" == "true" ]]; then
    printVariableOptional ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"} ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}
fi

[[ -n "${REQUIRED_EOT+x}" ]] && { echo '    echo ""'; }

echo "}"


# STARTER_URL=https://raw.githubusercontent.com/xshoji/bash-script-starter/master/ScriptStarter.sh
# curl -sf ${STARTER_URL} |bash -s - \
#   -n FunctionStarter \
#   -a xshoji \
#   -d "This script generates a template of bash function." \
#   -r naming,scriptName,"Script name." \
#   -o description,"Description","Description of this script. [ example: --description \"ScriptStarter's description here.\" ]" \
#   -o required,"paramName\,sample\,description","Required parameter setting. [ example: --required id\,1001\,\"Primary id here.\" ]" \
#   -o optional,"paramName\,sample\,description\,defaultValue(omittable)","Optional parameter setting. [ example: --option name\,xshoji\,\"User name here.\"\,defaultUser ]" \
#   -o flag,"flagName\,description","Optional flag parameter setting. [ example: --flag dryRun\,\"Dry run mode.\" ]" \
#   -s > /tmp/test.sh; open /tmp/test.sh

