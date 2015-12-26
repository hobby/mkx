#!/bin/bash
# vim:ts=4:sw=4:expandtab

############################################################
# NAME
#     completion_mkx.sh - bash completion for mkx
#
# AUTHORS
#     neiku project <ku7d@qq.com>
#
# VERSION
#     2015/12/26: 支持自动补全mk/mkd(options/targets)
#
############################################################

function _complete_callback_mk()
{
    COMPREPLY=()

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pre="${COMP_WORDS[COMP_CWORD-1]}"
    local opt="-f <makefile> -C <directory>"

    # options
    if [[ "$pre" == "-f" ]] ; then
        COMPREPLY=( $(compgen -W "`ls [Mm]akefile* GNUmakefile* 2>/dev/null`" -- "$cur") )
        return 0
    fi
    if [[ "$pre" == "-C" ]] ; then
        COMPREPLY=( $(compgen -W "`find . -maxdepth 1 -type d`" -- "$cur") )
        return 0
    fi
    if [[ "$cur" == -* ]] ; then
        COMPREPLY=( $(compgen -W "$opt" -- "$cur") )
        return 0
    fi

    # targets
    local submakedirs="`make -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
    if [[ "$submakedirs" != "" ]] ; then
        COMPREPLY=( $(ls) )
        return 0
    fi
    local targets="`make -n -p 2>/dev/null | grep '^OUTPUT =' | tail -1 | cut -c10-`"
    if [[ "$targets" == "" ]] ; then
        COMPREPLY=( $(ls) )
        return 0
    fi

    COMPREPLY=( $(compgen -W "$targets" -- "$cur") )
    return 0
}
complete -F _complete_callback_mk mk
complete -F _complete_callback_mk mkd
