#!/bin/bash
#
# NAME
#        schemaspy2svg.sh - Use SVG graphics for SchemaSpy
#
# SYNOPSIS
#        schemaspy2svg.sh [OPTION]... DIRECTORY...
#
# DESCRIPTION
#        Generates SVG files from the source .dot files and replaces the URLs in
#        the markup.
#
#        -h, --help
#               display this information and quit
#
#        -v, --verbose
#               verbose output
#
# EXAMPLES
#        schemaspy2svg.sh ~/SchemaSpy/*
#               Convert all DB exports in ~/SchemaSpy/.
#
# BUGS
#        https://github.com/l0b0/schemaspy2svg/issues
#
# COPYRIGHT
#        Copyright © 2010-2011 Victor Engmark. License GPLv3+: GNU GPL
#        version 3 or later <http://gnu.org/licenses/gpl.html>.
#        This is free software: you are free to change and redistribute it.
#        There is NO WARRANTY, to the extent permitted by law.
#
################################################################################

set -o errexit
set -o nounset
set -o noclobber

cmdname="$(basename -- "$0")"
directory="$(dirname -- "$0")"

patch_path="${directory}/schemaSpy.css.patch"

# Exit codes from /usr/include/sysexits.h, as recommended by
# http://www.faqs.org/docs/abs/HTML/exitcodes.html
EX_USAGE=64       # command line usage error

warning()
{
    # Output warning messages
    # Color the output red if it's an interactive terminal
    # @param $1...: Messages

    test -t 1 && tput setf 4

    printf '%s\n' "$@" >&2

    test -t 1 && tput sgr0 # Reset terminal
}

error()
{
    # Output error messages with optional exit code
    # @param $1...: Messages
    # @param $N: Exit code (optional)

    messages=( "$@" )

    # If the last parameter is a number, it's not part of the messages
    eval last_parameter="\$$#"
    if [[ "$last_parameter" =~ ^[0-9]*$ ]]
    then
        exit_code=$last_parameter
        unset messages[$((${#messages[@]} - 1))]
    fi

    warning "${messages[@]}"

    exit ${exit_code:-$EX_UNKNOWN}
}

usage()
{
    # Print documentation until the first empty line
    # @param $1: Exit code (optional)
    while IFS= read line
    do
        if [ -z "$line" ]
        then
            exit ${1:-0}
        elif [ "${line:0:2}" == '#!' ]
        then
            # Shebang line
            continue
        fi
        echo "${line:2}" # Remove comment characters
    done < "$0"
}

verbose_echo()
{
    # @param $1: Optionally '-n' for echo to output without newline
    # @param $(1|2)...: Messages
    if [ "${verbose:-}" ]
    then
        if [ "$1" = "-n" ]
        then
            $newline='-n'
            shift
        fi

        while [ -n "${1:-}" ]
        do
            echo -e ${newline:-} "$1" >&2
            shift
        done
    fi
}

# Process parameters
params="$(getopt -o hv -l help,verbose --name "$cmdname" -- "$@")"

if [ $? -ne 0 ]
then
    usage
fi

eval set -- "$params"

while true
do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            verbose='--verbose'
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage $EX_USAGE
            ;;
    esac
done

if [ $# -eq 0 ]
then
    usage $EX_USAGE
fi

for path
do
    verbose_echo "Converting $path"

    dot -O -Tsvg ${path}/diagrams/*.dot
    dot -O -Tsvg ${path}/diagrams/summary/*.dot

    verbose_echo "Fix the URLs in SVG files"
    for file in ${path}/diagrams/summary/*.svg
    do
        perl -p -i -e "s#^^^<a xlink:href=\"#^<a target=\"_top\" xlink:href=\"../../#g" -- "$file"
    done

    for file in ${path}/diagrams/*.svg
    do
        perl -p -i -e "s#^^^<a xlink:href=\"#^<a target=\"_top\" xlink:href=\"../tables/#g" -- "$file"
    done

    verbose_echo "Refer to SVG instead of PNG images in HTML files"
    for file in ${path}/*.html ${path}/tables/*.html
    do
        perl -p -i -e "s#(<)img([^>]*)src(='[^']*)\.png'#\1object type=\"image/svg+xml\"\2data\3.dot.svg'#g" -- "$file"
    done

    verbose_echo "Undo silly hiding CSS"
    patch -p0 "${path}/schemaSpy.css" < "$patch_path"

    verbose_echo "Clean up backup files and no longer needed PNG / DOT files"
    rm -- ${path}/diagrams/*.png ${path}/diagrams/summary/*.png
done
