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
#     2015/12/27: 支持自动补全mk/mkd/mkc(-f/-C选项)
#     2016/01/10: 支持自动补全mkr/mkt/mks
#     2016/01/22: 支持自动补全mkrun/mkm
#     2016/01/23: 解决无法正常输出带有#的配置问题
#                 完善mkm find所有子模块的自动补全
#                 完善mkm del所有子模块的自动补全
#     2016/02/16: 支持自定义默认target变量名(key => output-name)
#                 (默认使用OUTPUT做为默认target变量名)
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
    output="`mkm get config output-name OUTPUT`"
    length="$((${#output} + 4))"
    targets="`make ${makeflags} -n -p 2>/dev/null | grep "^$output =" | tail -n1 | cut -c$length-`"
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
    output="`mkm get config output-name OUTPUT`"
    length="$((${#output} + 4))"
    targets="`make ${makeflags} -n -p 2>/dev/null | grep "^$output =" | tail -n1 | cut -c$length-`"
    if [[ "$targets" == "" ]] ; then
        # target not fond, try configed-targets
        targets="`mkm list target 2>/dev/null
                 | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}'
                 | tr ' ' '\n'
                 | sed '/^$/d'
                 | sort -u`"
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

function _complete_callback_mkrun()
{
    local cur len word

    COMPREPLY=()

    len=${#COMP_WORDS[@]}
    cur="${COMP_WORDS[COMP_CWORD]}"
    if [ $len -le 2 ] ; then
        # mkrun <> or mkrun <cmdtype>
        word="`mkm list command 2>/dev/null | awk '{print $2}' | sort -u`"
    else
        # mkrun cmdtype <target> ...
        word="`mkm list command 2>/dev/null | awk '{print $1}' | sort -u`"
    fi
    COMPREPLY=( $(compgen -W "$word" -- "$cur") )

    return 0
}
complete -F _complete_callback_mkrun mkrun

function _complete_callback_mkm()
{
    local cur len word
    local cmd mod opt scope target module

    COMPREPLY=()

    len=${#COMP_WORDS[@]}
    cur="${COMP_WORDS[COMP_CWORD]}"

    # mkm <> or mkm <cmd>
    if [ $len -le 2 ] ; then
        word="add del find get list path"
        COMPREPLY=( $(compgen -W "$word" -- "$cur") )
        return 0
    fi

    # mkm cmd <mod> ...
    if [ $len -le 3 ] ; then
        cmd="${COMP_WORDS[1]}"
        if [ "$cmd" = "del" ] ; then
            word="command commandtpl config module target"
        elif [ "$cmd" = "get" ] ; then
            word="config"
        else
            word="command commandtpl config module target targetreg"
        fi
        COMPREPLY=( $(compgen -W "$word" -- "$cur") )
        return 0
    fi

    # mkm cmd mod <scope (--system|--global)> ...
    opt="--system --global"
    cmd="${COMP_WORDS[1]}"
    mod="${COMP_WORDS[2]}"
    if [ "$cmd" = "path" -o "$cmd" = "list" ] ; then
        word="$opt"
        COMPREPLY=( $(compgen -W "$word" -- "$cur") )
        return 0
    fi
    if [ "$cmd" = "find" ] ; then
        if [ "$mod" = "target" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm find target scope <target>
                if [ $len -le 5 ] ; then
                    word="`mkm list target $scope 2>/dev/null \
                    | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' \
                    | tr ' ' '\n' \
                    | sed '/^$/d' \
                    | sort -u`"
                fi
            elif [ $len -le 4 ] ; then
                # mkm find target <scope> <target>
                word="`mkm list target 2>/dev/null \
                      | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' \
                      | tr ' ' '\n' \
                      | sed '/^$/d' \
                      | sort -u`"
                word="$opt $word"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "module" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm find module scope <module>
                if [ $len -le 5 ] ; then
                    word="`mkm list module $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                fi
            elif [ $len -le 4 ] ; then
                # mkm find module <scope> <module>
                word="`mkm list module 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
                word="$opt $word"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "config" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm find config scope <key>
                if [ $len -le 5 ] ; then
                    word="`mkm list config $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                fi
            elif [ $len -le 4 ] ; then
                # mkm find config <scope> <key>
                word="`mkm list config 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
                word="$opt $word"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "command" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                if [ $len -le 5 ] ; then
                    # mkm find command scope <target>
                    word="`mkm list command $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                elif [ $len -le 6 ] ; then
                    # mkm find command scope target <cmdtype>
                    target="${COMP_WORDS[4]}"
                    word="`mkm list command $scope 2>/dev/null \
                          | grep -w -P "^$target[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            else
                if [ $len -le 4 ] ; then
                    # mkm find command <scope> <target>
                    word="`mkm list command 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                    word="$opt $word"
                elif [ $len -le 5 ] ; then
                    # mkm find command target <cmdtype>
                    target="${COMP_WORDS[3]}"
                    word="`mkm list command 2>/dev/null \
                          | grep -w -P "^$target[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "commandtpl" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                if [ $len -le 5 ] ; then
                    # mkm find commandtpl scope <module>
                    word="`mkm list commandtpl $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                elif [ $len -le 6 ] ; then
                    # mkm find commandtpl scope module <cmdtype>
                    module="${COMP_WORDS[4]}"
                    word="`mkm list commandtpl $scope 2>/dev/null \
                          | grep -w -P "^$module[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            else
                if [ $len -le 4 ] ; then
                    # mkm find commandtpl <scope> <module>
                    word="`mkm list commandtpl 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                    word="$opt $word"
                elif [ $len -le 5 ] ; then
                    # mkm find commandtpl module <cmdtype>
                    module="${COMP_WORDS[3]}"
                    word="`mkm list commandtpl 2>/dev/null \
                          | grep -w -P "^$module[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "targetreg" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm find targetreg scope <target>
                if [ $len -le 5 ] ; then
                    COMPREPLY=( $(compgen -f -- "$cur") )
                    return 0
                fi
            elif [ $len -le 4 ] ; then
                # mkm find targetreg <scope> <target>
                COMPREPLY=( $(compgen -W "$opt" -f -- "$cur") )
                return 0
            fi
        fi

        return 0
    fi
    if [ "$cmd" = "del" ] ; then
        if [ "$mod" = "target" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm del target scope <target>...
                word="`mkm list target $scope 2>/dev/null \
                      | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' \
                      | tr ' ' '\n' \
                      | sed '/^$/d' \
                      | sort -u`"
            elif [ $len -le 4 ] ; then
                # mkm del target <scope> <target>...
                word="`mkm list target 2>/dev/null \
                      | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' \
                      | tr ' ' '\n' \
                      | sed '/^$/d' \
                      | sort -u`"
                word="$opt $word"
            else
                # mkm del target <target>...
                word="`mkm list target 2>/dev/null \
                      | awk '{for(i=3;i<=NF;i++) printf $i""FS; print ""}' \
                      | tr ' ' '\n' \
                      | sed '/^$/d' \
                      | sort -u`"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "module" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm del module scope <module>...
                word="`mkm list module $scope 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
            elif [ $len -le 4 ] ; then
                # mkm del module <scope> <module>...
                word="`mkm list module 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
                word="$opt $word"
            else
                # mkm del module <module>...
                word="`mkm list module 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "config" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                # mkm del config scope <key>...
                word="`mkm list config $scope 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
            elif [ $len -le 4 ] ; then
                # mkm del config <scope> <key>...
                word="`mkm list config 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
                word="$opt $word"
            else
                # mkm del config <key>...
                word="`mkm list config 2>/dev/null \
                      | awk '{print $1}' \
                      | sort -u`"
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "command" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                if [ $len -le 5 ] ; then
                    # mkm del command scope <target>
                    word="`mkm list command $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                elif [ $len -le 6 ] ; then
                    # mkm del command scope target <cmdtype>
                    target="${COMP_WORDS[4]}"
                    word="`mkm list command $scope 2>/dev/null \
                          | grep -w -P "^$target[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            else
                if [ $len -le 4 ] ; then
                    # mkm del command <scope> <target>
                    word="`mkm list command 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                    word="$opt $word"
                elif [ $len -le 5 ] ; then
                    # mkm del command target <cmdtype>
                    target="${COMP_WORDS[3]}"
                    word="`mkm list command 2>/dev/null \
                          | grep -w -P "^$target[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        if [ "$mod" = "commandtpl" ] ; then
            scope="${COMP_WORDS[3]}"
            if [ "$scope" = "--system" -o "$scope" = "--global" ] ; then
                if [ $len -le 5 ] ; then
                    # mkm del commandtpl scope <module>
                    word="`mkm list commandtpl $scope 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                elif [ $len -le 6 ] ; then
                    # mkm del commandtpl scope module <cmdtype>
                    module="${COMP_WORDS[4]}"
                    word="`mkm list commandtpl $scope 2>/dev/null \
                          | grep -w -P "^$module[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            else
                if [ $len -le 4 ] ; then
                    # mkm del commandtpl <scope> <module>
                    word="`mkm list commandtpl 2>/dev/null \
                          | awk '{print $1}' \
                          | sort -u`"
                    word="$opt $word"
                elif [ $len -le 5 ] ; then
                    # mkm del commandtpl module <cmdtype>
                    module="${COMP_WORDS[3]}"
                    word="`mkm list commandtpl 2>/dev/null \
                          | grep -w -P "^$module[ \t]*" \
                          | awk '{print $2}' \
                          | sort -u`"
                fi
                # no need auto-complete
            fi
            COMPREPLY=( $(compgen -W "$word" -- "$cur") )
            return 0
        fi

        return 0
    fi
    if [ "$cmd" = "get" ] ; then
        if [ "$mod" = "config" ] ; then
            scope="${COMP_WORDS[3]}"
            word="`mkm list config $scope 2>/dev/null \
                  | awk '{print $1}' \
                  | sort -u`"
            word="$opt $word"
        fi

        COMPREPLY=( $(compgen -W "$word" -- "$cur") )
        return 0
    fi
    # TODO: add ...

    return 0
}
complete -F _complete_callback_mkm mkm
