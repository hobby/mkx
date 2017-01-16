#!/usr/bin/env bash
# vim:ts=4:sw=4:expandtab

###########################################################################
# NAME
#     mk - a toy for make targets.
#
# SYNOPSIS
#     mk
#     mk [ options ] [ targets ] ...
#
#     debug=on mk ...
#
# OPTIONS
#       -C DIRECTORY  Change to DIRECTORY before doing anything.
#       -f FILE       Read FILE as a makefile.
#       -h            Print this message and exit.
#       -j [N]        Allow N jobs at once; infinite jobs with no arg.
#       -l [N]        Don't start multiple jobs unless load is below N.
#       -n            Don't actually run any commands; just print them.
#       -p            Print make's internal database.
#
#       -x            Don't use mkx makefile.
#       -z            Don't use make-flags config.
#
# AUTHORS
#     neiku project <ku7d@qq.com>
#
# VERSION
#     2015/12/11: 支持目录递归、编译前/后自定义命令
#     2016/01/29: 支持自定义make选项, 配置名称: make-flags
#                 (允许静态配置[文本]或者动态配置[命令])
#     2016/01/31: 支持自动生成(完整依赖)makefile(默认关闭)，使用生成的
#                 makefile进行(自动增量)编译;
#                 配置方式:
#                 using-mkx-makefile = yes
#                 makefile-tpl-path = /path/to/mkxrc_makefiletpl
#                 模板预定义变量:
#                 用户当前使用makefile: {_origin_makefile_}
#     2016/02/03: 支持目录级增量编译
#                 支持自定义选项(make选项集的子集 + mkx扩展)
#                 支持-x临时不使用mkx makefile
#                 支持-z临时不使用make-flags配置
#     2016/02/16: 支持自定义默认target变量名(key => output-name)
#                 (默认使用OUTPUT做为默认target变量名)
#     2016/03/13: 支持预设pre-make/post-make运行时变量
#                 MKX_PWD     = current working directory
#                 MKX_OPTIONS = command-line's options
#                 MKX_TARGETS = targets to be maked
#                 MKX_ORIGIN_MAKEDIR  = origin makedir  (-C)
#                 MKX_ORIGIN_MAKEFILE = origin makefile (-f)
#                 MKX_REAL_MAKEFILE   = real makefile (origin|mkx makefile)
#                 (基于环境变量通信, 优于命令行方式通信)
#                 支持捕捉依赖生成异常,避免生成垃圾(sed***)临时文件
#     2016/03/18: 支持通过环境变量与make通信生成mkx makefile
#                 (废弃基于sed的变量替换文件生成机制、废弃MKX_PWD环境变量)
#     2016/03/25: 支持makefile-tpl-path配置引用shell变量(例如$HOME)
#     2016/04/13: 支持精确识别编译命令，避免无法正常生成依赖问题
#                 (含有-c开关选项，而不是只含有-c关键字的命令才是编译命令)
#     2016/06/18: 支持允许makefile不存在默认输出目标(OUTPUT)变量
#     2017/01/16: 支持跨平台
#                 - 通过env程序+PATH变量动态查询bash，控制权
#                   、准确性都得到保障
#
###########################################################################

# help
function help()
{
    echo "Usage: mk [ options ] [ targets ] ..."
    echo "Options:"
    echo "  -C DIRECTORY  Change to DIRECTORY before doing anything."
    echo "  -f FILE       Read FILE as a makefile."
    echo "  -j [N]        Allow N jobs at once; infinite jobs with no arg."
    echo "  -h            Print this message and exit."
    echo "  -l [N]        Don't start multiple jobs unless load is below N."
    echo "  -n            Don't actually run any commands; just print them."
    echo "  -p            Print make's internal database."
    echo ""
    echo "  -x            Don't use mkx makefile."
    echo "  -z            Don't use make-flags config."
    echo ""
    echo "Report bugs to <ku7d@qq.com>"
}

# mk -C {makedir} -f {makefile} {cmdline_options} {cmdline_targets}
makedir=""
makefile=""
cmdline_options=""
cmdline_targets=""
using_mkx_makefile_cmdline="yes"
using_makeflags_cmdline="yes"

# parse cmdline
mklog debug "origin-args:[$@]"
temp=$(getopt -o "C:f:hj::l::npxz" --long "" -n "mk" -- "$@")
if [ $? != 0 ] ; then
    echo "`help`" >&2
    exit 1
fi
eval set -- "$temp"
mklog debug "parsed-args:[$temp]"
while true
do
    case "$1" in
        -C) makedir="$2" ;  shift 2 ;;
        -f) makefile="$2" ; shift 2 ;;
        -h) echo "`help`" >&2; exit 0;;
        -j) cmdline_options="$cmdline_options -j$2"; shift 2;;
        -l) cmdline_options="$cmdline_options -l$2"; shift 2;;
        -n) cmdline_options="$cmdline_options -n"; shift 1;;
        -p) cmdline_options="$cmdline_options -p"; shift 1;;
        -x) using_mkx_makefile_cmdline="no"; shift 1;;
        -z) using_makeflags_cmdline="no"; shift 1;;
        --) shift ; break ;;
        *)  echo "parse options error!" >&2 ; exit 1 ;;
    esac
done
cmdline_targets="$@"
mklog debug "makedir:[$makedir], makefile:[$makefile]," \
            "cmdline_options:[$cmdline_options], cmdline_targets:[$cmdline_targets]," \
            "using_mkx_makefile_cmdline:[$using_mkx_makefile_cmdline]," \
            "using_makeflags_cmdline:[$using_makeflags_cmdline]"

# wrapper
succ_exit() { [ -n "$makedir" ] && echo "mk: Leaving directory '$makedir'"; exit 0; }
fail_exit() { [ -n "$makedir" ] && echo "mk: Leaving directory '$makedir'"; exit 1; }

# go into make directory if need
if [ -n "$makedir" ] ; then
    if [ ! -d "$makedir" ] ; then
        mklog error "check directory fail, directory:[$makedir]"
        exit 1
    fi

    echo "mk: Entering directory '$makedir'"
    cd "$makedir" || fail_exit
fi

# get makefile from cmdline(by user) or make(auto load)
if [ -z "$makefile" ] ; then
    makefile="`make $cmdline_options $cmdline_targets -n -p 2>/dev/null \
              | grep '^MAKEFILE_LIST' \
              | head -n1 \
              | awk '{printf $3}'`"
    if [ -z "$makefile" ] ; then
        mklog error "makefile not found, make args:[$cmdline_options $cmdline_targets]"
        fail_exit
    fi
fi
if [ ! -f "$makefile" ] ; then
    mklog error "check makefile fail, makefile:[$makefile]"
    fail_exit
fi
mklog debug "makefile:[$makefile]"

# get make's internal database
makedata="`make -f $makefile $cmdline_options $cmdline_targets -n -p 2>/dev/null`"

# maybe mk for sub directorys
submakedirs="`echo "$makedata" | grep '^DIRS =' | tail -n1 | cut -c8-`"
mklog debug "submakedirs=$submakedirs"
if [ -n "$submakedirs" ] ; then
    for subdir in $submakedirs
    do
        if [ "${subdir:0:1}" = "/" ] ; then
            mk -C $subdir $cmdline_options
        else
            mk -C `pwd`/$subdir $cmdline_options
        fi
    done
    mklog debug "mk for directorys end"
    succ_exit
fi

# get targets makefile if need
if [ -z "$cmdline_targets" ] ; then
    # default targets from $output var in makefile
    output="`mkm get config output-name OUTPUT`"
    length="$((${#output} + 4))"
    makefile_targets="`echo "$makedata" | grep "^$output =" | cut -c$length-`"
    cmdline_targets="$makefile_targets"
fi

# export env for user-defined command & make (gen mkx makefile)
export MKX_OPTIONS="$cmdline_options" \
       MKX_TARGETS="$cmdline_targets" \
       MKX_ORIGIN_MAKEDIR="$makedir" \
       MKX_ORIGIN_MAKEFILE="$makefile"

# pre make
cmd="`mkm get config pre-make`"
mklog debug "pre-make:[$cmd]"
if [ -n "$cmd" ] ; then
    pwd="`pwd`"
    eval "$cmd"
    if [ $? -ne 0 ] ; then
        mklog error "run pre-make fail, cmd:[$cmd]"
    fi
    cd "$pwd"
fi

# no using mkx makefile default
using_mkx_makefile_config="`mkm get config using-mkx-makefile`"
mklog debug "using mkx makefile config:[$using_mkx_makefile_config]"
if [   "$using_mkx_makefile_config"  = "yes" \
    -a "$using_mkx_makefile_cmdline" = "yes" ] ; then
    # prepare makefile for ...
    makefile_org="$makefile"
    makefile_mkx=".$makefile_org.mkx"
    makefile_dep="$makefile_mkx"
    makefile="$makefile_mkx"

    # gen mkx makefile with tpl
    if [ ! -f $makefile_dep ] ; then
        # always cleanup and premake 'by user by user by user'
        # for gen all deps from org makefile
        # when mkx makefile not exist (by mkc)
        # or mkx makefile tpl changed (by user)
        # eg: run mkc && run pre-make
        makefile_dep=$makefile_org

        # gen new mkx makefile from tpl
        makefile_tpl_path="`mkm get config makefile-tpl-path`"
        makefile_tpl_path="`eval echo $makefile_tpl_path`"
        mklog debug "makefile tpl path:[$makefile_tpl_path]"
        if [ -z "$makefile_tpl_path" ] ; then
            mklog error "makefile tpl path not found, config:[makefile_tpl_path]"
            fail_exit
        fi
        if [ ! -s "$makefile_tpl_path" ] ; then
            mklog error "makefile tpl not found or empty, path:[$makefile_tpl_path]"
            fail_exit
        fi
        cp -f "$makefile_tpl_path" $makefile_mkx
    fi
    mklog debug "makefile-dep:[$makefile_dep]"

    # update targets's deps into mkx makefile
    mklog tip "generate deps for"
    make -f $makefile_dep $cmdline_options $cmdline_targets -n 2>/dev/null \
    | grep -P "(^g++|^gcc).*[ \t]-c[ \t].*$" \
    | while read mkcmd; do
        # get deps with -MM (user defined dep)
        depcmd="`echo -n "$mkcmd" | sed -e 's/-o[ \t]*[^ \t]*//g' -e 's/$/ -MM/g'`"
        dep="`eval $depcmd 2>&1`"
        if [ $? -ne 0 ] ; then
            echo -e "\n$dep"
            mklog debug "gen deps fail, depcmd:[$depcmd]"
            exit 1
        fi
        dep="`echo -n "$dep" | tr -d '\\\\\n'`"
        mklog debug "depcmd:[$depcmd], dep:[$dep]"

        # update deps (generally speaking, $name will not empty here)
        name="`echo -n "$dep" | cut -d: -f1`"
        if [ -n "$name" ] ; then
            sed -i "/$name/d" $makefile_mkx
            echo "$dep" >> $makefile_mkx
        fi

        # progress
        mklog tip " $name"
    done || fail_exit
    echo
fi

# export env for user-defined command & make (gen mkx makefile)
export MKX_REAL_MAKEFILE="$makefile"

# make flags
makeflags="`mkm get config make-flags`"
if [ "$using_makeflags_cmdline" = "no" ] ; then
    makeflags=""
fi
mklog debug "make-flags:[$makeflags]," \
            "using_makeflags_cmdline:[$using_makeflags_cmdline]"

# make targets with $makefile
make="make -f $makefile $makeflags $cmdline_options $cmdline_targets"
mklog debug "make command:[$make]"
eval $make
if [ $? -ne 0 ] ; then
    mklog error "make fail, make command:[$make]"
    fail_exit
fi

# post make
cmd="`mkm get config post-make`"
mklog debug "post-make:[$cmd]"
if [ -n "$cmd" ] ; then
    pwd="`pwd`"
    eval "$cmd"
    if [ $? -ne 0 ] ; then
        mklog error "run post-make fail, cmd:[$cmd]"
    fi
    cd "$pwd"
fi

# all done
succ_exit
