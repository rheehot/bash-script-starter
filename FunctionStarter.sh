#!/bin/bash

function usage()
{
cat << "_EOT_"

   FunctionStarter   
  ------------------- author: xshoji

_EOT_
cat << _EOT_
  Usage:
    ./$(basename "$0") --naming functionName [ --description "A function's desctiption." --required paramName,sample --required ... --option paramName,sample --option ... --flag flagName --flag ... ]

  Description:
    This script generates a template of bash function.
 
  Required parameters:
    --naming,-n functionName : A function name.

  Optional parameters:
    --description,-d "Description"             : A function's desctiption. [ example: --description "A function's description here." ]
    --required,-r paramName,sample,description : Required parameter setting. [ example: --required id,1001,"Primary id here." ]
    --option,-o paramName,sample,description   : Optional parameter setting. [ example: --option name,xshoji,"User name here." ]
    --flag,-f flagName,description             : Optional flag parameter setting. [ example: --flag dryRun,"Dry run mode." ]

_EOT_
exit 1
}

#==========================================
# Preparation
#==========================================

set -eu

# Parse parameters
ARG_ORG=("$@")
ARGS_REQUIRED=()
ARGS_OPTIONAL=()
ARGS_FLAG=()
ARGS_DESCRIPTION=()

for ARG in "$@"
do
    SHIFT="true"
    ([ "${ARG}" == "--debug" ]) && { shift 1; set -eux; SHIFT="false"; }
    ([ "${ARG}" == "--naming" ]      || [ "${ARG}" == "-n" ]) && { shift 1; FUNCTION_NAME=${1}; SHIFT="false"; }
    ([ "${ARG}" == "--required" ]    || [ "${ARG}" == "-r" ]) && { shift 1; ARGS_REQUIRED+=("${1}"); SHIFT="false"; }
    ([ "${ARG}" == "--option" ]      || [ "${ARG}" == "-o" ]) && { shift 1; ARGS_OPTIONAL+=("$1"); SHIFT="false"; }
    ([ "${ARG}" == "--flag" ]        || [ "${ARG}" == "-f" ]) && { shift 1; ARGS_FLAG+=("${1}"); SHIFT="false"; }
    ([ "${ARG}" == "--env" ]         || [ "${ARG}" == "-e" ]) && { shift 1; ARGS_ENVIRONMENT+=("${1}"); SHIFT="false"; }
    ([ "${ARG}" == "--short" ]       || [ "${ARG}" == "-s" ]) && { shift 1; SHORT="true"; SHIFT="false"; }
    ([ "${ARG}" == "--description" ] || [ "${ARG}" == "-d" ]) && { shift 1; ARGS_DESCRIPTION+=("${1}"); SHIFT="false"; }
    ([ "${SHIFT}" == "true" ] && [ "$#" -gt 0 ]) && { shift 1; }
done
# Check require parameters
[ -z "${FUNCTION_NAME+x}" ] && { echo "[!] --naming is required. "; INVALID_STATE="true"; }
[ ! -z "${INVALID_STATE+x}" ] && { usage; exit 1; }
[ -z "${SHORT+x}" ] && { SHORT="false"; }
[ -z "${DESCRIPTION+x}" ] && { DESCRIPTION=""; }


#==========================================
# Functions
#==========================================

function printUsageExecutionExampleBase() {

    echo "#######################################"
    for ARG in "$@"
    do
      echo "# ${ARG}"
    done
    echo "#"
    echo "# Usage:"

}



function printUsageExecutionExample() {

    # Add required parameters
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local SAMPLE=$(awk -F',' '{print $2}' <<<${1})
        echo -n ' '"--${PARAM_NAME} ${SAMPLE}"
        shift 1
    done
}



function printUsageExecutionExampleFlag() {

    # Add required parameters
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        echo -n ' '"--${PARAM_NAME}"
        shift 1
    done
}




function printParameterDescription() {
    for ARG in "$@"
    do
        # - [csv - Printing column separated by comma using Awk command line - Stack Overflow](https://stackoverflow.com/questions/26842504/printing-column-separated-by-comma-using-awk-command-line)
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local SAMPLE=$(awk -F',' '{print $2}' <<<${1})
        local DESCRIPTION=$(awk -F',' '{print $3}' <<<${1})
        local PARAM_NAME_SHORT=$(cut -c 1 <<<${PARAM_NAME})
        [ "${SAMPLE}" == "" ] && { SAMPLE=${PARAM_NAME}; }
        [ "${DESCRIPTION}" == "" ] && { DESCRIPTION="${SAMPLE} is specified as ${PARAM_NAME}"; }
        local IS_USED_SHORT_PARAM=$(grep "${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        echo -n "#   --${PARAM_NAME}"
        if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
            ARGS_SHORT+=("${PARAM_NAME_SHORT}")
            echo -n ",-${PARAM_NAME_SHORT}"
        fi
        echo " ${SAMPLE} : ${DESCRIPTION}"
        shift 1
    done
}



function printParameterDescriptionFlag() {
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local PARAM_NAME_SHORT=$(cut -c 1 <<<${PARAM_NAME})
        local DESCRIPTION=$(awk -F',' '{print $2}' <<<${1})
        [ "${DESCRIPTION}" == "" ] && { DESCRIPTION="Enable ${PARAM_NAME} flag"; }
        local IS_USED_SHORT_PARAM=$(grep "${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        echo -n "#   --${PARAM_NAME}"
        if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
            ARGS_SHORT+=("${PARAM_NAME_SHORT}")
            echo -n ",-${PARAM_NAME_SHORT}"
        fi
        echo " : ${DESCRIPTION}"
        shift 1
    done
}



function printUsageFunctionBottomPart() {
    echo "#######################################"
}

function printFunctionTopPart() {
    echo "function ${1}() {"
}

function printLocalDeclarationArgument() {
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        echo '    local '${VAR_NAME}='""'
        shift 1
    done
}

function printParseArgument() {
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local PARAM_NAME_SHORT=$(cut -c 1 <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        local CONDITION='[ "${_ARG}" == "--'"${PARAM_NAME}"'" ]'
        local IS_USED_SHORT_PARAM=$(grep "1${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
            ARGS_SHORT+=("1${PARAM_NAME_SHORT}")
            CONDITION='('"${CONDITION}"' || [ "${_ARG}" == "-'"${PARAM_NAME_SHORT}"'" ])'
        fi
        echo '        '"${CONDITION}"' && { shift 1; '"${VAR_NAME}"'="${1}"; _SHIFT="false"; }'
        shift 1
    done
}


function printParseArgumentFlag() {
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local PARAM_NAME_SHORT=$(cut -c 1 <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        local CONDITION='[ "${_ARG}" == "--'"${PARAM_NAME}"'" ]'
        local IS_USED_SHORT_PARAM=$(grep "1${PARAM_NAME_SHORT}" <<<$(echo ${ARGS_SHORT[@]+"${ARGS_SHORT[@]}"}) || true)
        if [ "${SHORT}" == "true" ] && [ "${IS_USED_SHORT_PARAM}" == "" ]; then
            ARGS_SHORT+=("1${PARAM_NAME_SHORT}")
            CONDITION='('"${CONDITION}"' || [ "${_ARG}" == "-'"${PARAM_NAME_SHORT}"'" ])'
        fi
        echo '        '"${CONDITION}"' && { shift 1; '"${VAR_NAME}"'="true"; _SHIFT="false"; }'
        shift 1
    done
}



function printCheckRequiredArgument() {
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        echo '    [ "${'"${VAR_NAME}"'}" == "" ] && { echo "[!] '${FUNCTION_NAME}'() requires --'"${PARAM_NAME}"' "; _INVALID_STATE="true"; }'
        shift 1
    done
}


function printVariableRequired() {
    echo '    echo "  Required arguments"'
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        echo '    echo "    - '"${PARAM_NAME}"': ${'"${VAR_NAME}"'}"'
        shift 1
    done
}

function printVariableOptional() {
    echo '    echo "  Optional arguments"'
    for ARG in "$@"
    do
        local PARAM_NAME=$(awk -F',' '{print $1}' <<<${1})
        local VAR_NAME=$(echo ${PARAM_NAME} | perl -pe 's/(?:^|_)(.)/\U$1/g' | perl -ne 'print lc(join("_", split(/(?=[A-Z])/)))' |awk '{print toupper($1)}')
        echo '    echo "    - '"${PARAM_NAME}"': ${'"${VAR_NAME}"'}"'
        shift 1
    done
}






#==========================================
# Main
#==========================================

# Print usage example
printUsageExecutionExampleBase ${ARGS_DESCRIPTION[@]+"${ARGS_DESCRIPTION[@]}"}
echo -n "#   ${FUNCTION_NAME}"

# - [Bash empty array expansion with `set -u` - Stack Overflow](https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u)
printUsageExecutionExample ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}

if [ ${#ARGS_OPTIONAL[@]} -gt 0 ] || [ ${#ARGS_FLAG[@]} -gt 0 ]; then
    echo -n " ["
fi

printUsageExecutionExample ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printUsageExecutionExampleFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}

if [ ${#ARGS_OPTIONAL[@]} -gt 0 ] || [ ${#ARGS_FLAG[@]} -gt 0 ]; then
    echo -n " ]"
fi
echo ""
echo "# "


if [ ${#ARGS_REQUIRED[@]} -gt 0 ]; then
    echo "# Required arguments:"
    printParameterDescription "${ARGS_REQUIRED[@]}"
    echo "# "
fi

echo "# Optional arguments:"
if [ ${#ARGS_OPTIONAL[@]} -gt 0 ] || [ ${#ARGS_FLAG[@]} -gt 0 ]; then
    printParameterDescription ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
    printParameterDescriptionFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}
fi

printUsageFunctionBottomPart


printFunctionTopPart ${FUNCTION_NAME}


cat << "__EOT__"
    # Argument parsing
    local _ARG=""; local _SHIFT=""; local _INVALID_STATE=""
__EOT__

printLocalDeclarationArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}
printLocalDeclarationArgument ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printLocalDeclarationArgument ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}

cat << "__EOT__"
    for _ARG in "$@"
    do
        local _SHIFT="true"
__EOT__

printParseArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}
printParseArgument ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"}
printParseArgumentFlag ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}

cat << "__EOT__"
        ([ "${_SHIFT}" == "true" ] && [ "$#" -gt 0 ]) && { shift 1; }
    done
__EOT__

[ ${#ARGS_REQUIRED[@]} -gt 0 ] && { echo "    # Check required arguments"; }
printCheckRequiredArgument ${ARGS_REQUIRED[@]+"${ARGS_REQUIRED[@]}"}

# Check invalid state
echo "    # Check invalid state"
echo '    [ "${_INVALID_STATE}" == "true" ] && { exit 1; }'
echo "    "
echo "    # Main"


if [ ${#ARGS_REQUIRED[@]} -gt 0 ] || [ ${#ARGS_OPTIONAL[@]} -gt 0 ] || [ ${#ARGS_FLAG[@]} -gt 0 ]; then
    echo '    echo ""'
    echo '    echo "'${FUNCTION_NAME}'()"'
    REQUIRED_EOT="true"
fi

if [ ${#ARGS_REQUIRED[@]} -gt 0 ]; then
    printVariableRequired "${ARGS_REQUIRED[@]}"
fi
if [ ${#ARGS_OPTIONAL[@]} -gt 0 ] || [ ${#ARGS_FLAG[@]} -gt 0 ]; then
    printVariableOptional ${ARGS_OPTIONAL[@]+"${ARGS_OPTIONAL[@]}"} ${ARGS_FLAG[@]+"${ARGS_FLAG[@]}"}
fi

[ ! -z "${REQUIRED_EOT+x}" ] && { echo '    echo ""'; }

echo "}"