#!/bin/bash
# vim:ts=4:sw=4:expandtab

############################################################
# NAME
#     mkx_completion.sh - bash completion for mkx
#
# AUTHORS
#     neiku project <ku7d@qq.com>
#
# VERSION
#     2015/12/26: 支持自动补全mk/mkd(options/targets)
#     2015/12/27: 支持自动补充mk/mkd/mkc(-f/-C选项)
#     2016/01/10: 支持自动补充mkr/mkt/mks
#
############################################################

function _complete_callback_mk()
{
    local cur pre opt len word
    local makefiles submakedirs targets
    local makeflags opt_makefile opt_makedir

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    pre="${COMP_WORDS[COMP_CWORD-1]}"
    opt="-f -C"

    # -f option-value
    opt_makefile=""
    len=${#COMP_WORDS[@]}
    for ((i = 0; i < $len; i++)) ; do
        word="${COMP_WORDS[$i]}"
        if [[ "$word" == -f* ]] ; then
            # -f<makefile> format, select the last one
            if [[ "${word:2}" != "" ]] ; then
                opt_makefile="${word:2}"
                continue
            fi
            # -f <makefile> format, select the last one
            if [[ $i < $len-1 ]] ; then
                word="${COMP_WORDS[$((i+1))]}"
                if [[ "$word" != "" ]] ; then
                    opt_makefile="$word"
                    continue
                fi
            fi
        fi
    done

    # -C option-value
    opt_makedir="."
    len=${#COMP_WORDS[@]}
    for ((i = 0; i < $len; i++)) ; do
        word="${COMP_WORDS[$i]}"
        if [[ "$word" == -C* ]] ; then
            # -f<makedir> format, select the last one
            if [[ "${word:2}" != "" && -d "${word:2}" ]] ; then
                opt_makedir="${word:2}"
                continue
            fi
            # -f <makedir> format, select the last one
            if [[ $i < $len-1 ]] ; then
                word="${COMP_WORDS[$((i+1))]}"
                if [[ "$word" != "" && -d "$word" ]] ; then
                    opt_makedir="$word"
                    continue
                fi
            fi
        fi
    done

    # make flags (-f/-C)
    makeflags=""
    if [[ "${opt_makedir}" != "" ]] ; then
        makeflags="${makeflags} -C ${opt_makedir}"
    fi
    if [[ "${opt_makefile}" != "" ]] ; then
        makeflags="${makeflags} -f ${opt_makefile}"
    fi

    # options-name
    if [[ "$pre" == "-f" ]] ; then
        makefiles="`ls ${opt_makedir}/[Mm]akefile* ${opt_makedir}/GNUmakefile* 2>/dev/null \
                    | while read file; do basename "$file"; done`"
        if [[ "$makefiles" == "" ]] ; then
            # makefile not found, just complete for file
            makefiles="`ls 2>/dev/null`"
        fi
        COMPREPLY=( $(compgen -W "$makefiles" -- "$cur") )
        return 0
    fi
    if [[ "$pre" == "-C" ]] ; then
        submakedirs="`make ${makeflags} -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
        if [[ "$submakedirs" == "" ]] ; then
            submakedirs="`find ${opt_makedir} -maxdepth 1 -type d 2>/dev/null`"
        fi
        if [[ "$submakedirs" == "" ]] ; then
            COMPREPLY=( $(compgen -W "`ls`" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "$submakedirs" -- "$cur") )
        fi
        return 0
    fi
    if [[ "$cur" == -* ]] ; then
        COMPREPLY=( $(compgen -W "$opt" -- "$cur") )
        return 0
    fi

    # targets
    submakedirs="`make ${makeflags} -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
    if [[ "$submakedirs" != "" ]] ; then
        # redirect to -C
        COMPREPLY=( "-C" )
        return 0
    fi
    targets="`make ${makeflags} -n -p 2>/dev/null | grep '^OUTPUT =' | tail -1 | cut -c10-`"
    if [[ "$targets" == "" ]] ; then
        # target not fond, just compete for file
        COMPREPLY=( $(compgen -W "`ls`" -- "$cur") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "$targets" -- "$cur") )
    return 0
}
complete -F _complete_callback_mk mk
complete -F _complete_callback_mk mkc
complete -F _complete_callback_mk mkd

function _complete_callback_mkr()
{
    local cur pre opt len word
    local makefiles submakedirs targets
    local makeflags opt_makefile opt_makedir

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    pre="${COMP_WORDS[COMP_CWORD-1]}"
    opt="-f -C"

    # -f option-value
    opt_makefile=""
    len=${#COMP_WORDS[@]}
    for ((i = 0; i < $len; i++)) ; do
        word="${COMP_WORDS[$i]}"
        if [[ "$word" == -f* ]] ; then
            # -f<makefile> format, select the last one
            if [[ "${word:2}" != "" ]] ; then
                opt_makefile="${word:2}"
                continue
            fi
            # -f <makefile> format, select the last one
            if [[ $i < $len-1 ]] ; then
                word="${COMP_WORDS[$((i+1))]}"
                if [[ "$word" != "" ]] ; then
                    opt_makefile="$word"
                    continue
                fi
            fi
        fi
    done

    # -C option-value
    opt_makedir="."
    len=${#COMP_WORDS[@]}
    for ((i = 0; i < $len; i++)) ; do
        word="${COMP_WORDS[$i]}"
        if [[ "$word" == -C* ]] ; then
            # -f<makedir> format, select the last one
            if [[ "${word:2}" != "" && -d "${word:2}" ]] ; then
                opt_makedir="${word:2}"
                continue
            fi
            # -f <makedir> format, select the last one
            if [[ $i < $len-1 ]] ; then
                word="${COMP_WORDS[$((i+1))]}"
                if [[ "$word" != "" && -d "$word" ]] ; then
                    opt_makedir="$word"
                    continue
                fi
            fi
        fi
    done

    # make flags (-f/-C)
    makeflags=""
    if [[ "${opt_makedir}" != "" ]] ; then
        makeflags="${makeflags} -C ${opt_makedir}"
    fi
    if [[ "${opt_makefile}" != "" ]] ; then
        makeflags="${makeflags} -f ${opt_makefile}"
    fi

    # options-name
    if [[ "$pre" == "-f" ]] ; then
        makefiles="`ls ${opt_makedir}/[Mm]akefile* ${opt_makedir}/GNUmakefile* 2>/dev/null \
                    | while read file; do basename "$file"; done`"
        if [[ "$makefiles" == "" ]] ; then
            # makefile not found, just complete for file
            makefiles="`ls 2>/dev/null`"
        fi
        COMPREPLY=( $(compgen -W "$makefiles" -- "$cur") )
        return 0
    fi
    if [[ "$pre" == "-C" ]] ; then
        submakedirs="`make ${makeflags} -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
        if [[ "$submakedirs" == "" ]] ; then
            submakedirs="`find ${opt_makedir} -maxdepth 1 -type d 2>/dev/null`"
        fi
        if [[ "$submakedirs" == "" ]] ; then
            COMPREPLY=( $(compgen -W "`ls`" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "$submakedirs" -- "$cur") )
        fi
        return 0
    fi
    if [[ "$cur" == -* ]] ; then
        COMPREPLY=( $(compgen -W "$opt" -- "$cur") )
        return 0
    fi

    # targets
    submakedirs="`make ${makeflags} -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
    if [[ "$submakedirs" != "" ]] ; then
        # redirect to -C
        COMPREPLY=( "-C" )
        return 0
    fi
    targets="`make ${makeflags} -n -p 2>/dev/null | grep '^OUTPUT =' | tail -1 | cut -c10-`"
    if [[ "$targets" == "" ]] ; then
        # target not fond, try configed-targets
        targets="`mkm list target 2>&1 | grep -v '#' | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' | tr ' ' '\n' | sed '/^$/d'`"
        if [[ "$targets" == "" ]] ; then
            COMPREPLY=( $(compgen -W "`ls`" -- "$cur") )
            return 0
        fi
    fi

    COMPREPLY=( $(compgen -W "$targets" -- "$cur") )
    return 0
}
complete -F _complete_callback_mkr mkr
complete -F _complete_callback_mkr mkt
complete -F _complete_callback_mkr mks
