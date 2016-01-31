#!/bin/bash
# vim:ts=4:sw=4:expandtab

############################################################
# NAME
#     mk - a toy for make targets.
#
# SYNOPSIS
#     mk
#     mk [ -f makefile ] [ -C directory ] [ -j [max-jobs] ] [ targets ] ...
#
#     debug=on mk ...
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
#
############################################################

# get make directory
makedir="`make $* -n -p 2>/dev/null | grep '^CURDIR :=' | tail -n1 | cut -c11-`"
if [ -z "$makedir" ] ; then
    mklog error "make directory not found, make args:[$*]"
    exit 1
fi
mklog debug "makedir:[$makedir]"

# maybe mk for sub directorys
submakedirs="`make $* -n -p 2>/dev/null | grep '^DIRS =' | tail -n1 | cut -c8-`"
mklog debug "submakedirs=$submakedirs"
if [ -n "$submakedirs" ] ; then
    for subdir in $submakedirs
    do
        if [ "${subdir:0:1}" = "/" ] ; then
            mk -C $subdir
        else
            mk -C $makedir/$subdir
        fi
    done
    mklog debug "mk for directorys end"
    exit 0
fi

# get rgets from cmdline
targets="`make $* -n -p 2>/dev/null | grep '^MAKECMDGOALS :=' | cut -c17-`"
if [ -z "$targets" ] ; then
    # default targets from OUTPUT var in makefile
    targets="`make $* -n -p 2>/dev/null | grep '^OUTPUT =' | cut -c10-`"
fi
if [ -z "$targets" ] ; then
    mklog error "need-make targets not found, make args:[$*]"
    exit 1
fi
mklog debug "targets(need make):[$targets]"

# pre make
cmd="`mkm get config pre-make`"
mklog debug "pre-make:[$cmd]"
pwd="`pwd`"
cd "$makedir"
eval "$cmd"
cd "$pwd"

# make flags
makeflags="`mkm get config make-flags`"
mklog debug "make-flags:[$makeflags]"

# cleanup cmdline's -f/--file/--makefile option
cmdline="`echo "$*" | sed -e 's/--makefile[ \t]*[^ \t]*//g' \
                          -e 's/--file[ \t]*[^ \t]*//g' \
                          -e 's/-f[ \t]*[^ \t]*//g'`"

# get current makefile
makefile="`make $* $targets -n -p | grep '^MAKEFILE_LIST' | awk '{printf $3}'`"

# do not using mkx makefile until you say yes
using_mkx_makefile="`mkm get config using-mkx-makefile`"
mklog debug "using mkx makefile:[$using_mkx_makefile]"
if [ "$using_mkx_makefile" = "yes" ] ; then
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
        mklog debug "makefile tpl path:[$makefile_tpl_path]"
        if [ -z "$makefile_tpl_path" ] ; then
            mklog error "makefile tpl path config not found, config key:[makefile_tpl_path]"
            exit 1
        fi
        if [ ! -f "$makefile_tpl_path" ] ; then
            mklog error "makefile tpl not found or empty, path:[$makefile_tpl_path]"
            exit 1
        fi
        cp -f "$makefile_tpl_path" $makefile_mkx
        sed -i "s/{_origin_makefile_}/$makefile_org/g" $makefile_mkx
    fi

    # update targets's deps into mkx makefile
    mklog tip "generate deps for"
    make -f $makefile_dep $cmdline $targets -n | grep -P "(g++|gcc).*\.o$" | while read mkcmd ; do
        # get deps with -MM (user defined dep)
        depcmd="`echo -n "$mkcmd" | sed 's/-o[ \t]*[^ \t]*/-MM/'`"
        dep="`eval $depcmd | tr -d '\\\\\n'`"

        # update deps (generally speaking, $name will not empty here)
        name="`echo -n "$dep" | cut -d: -f1`"
        sed -i "/$name/d" $makefile_mkx
        echo "$dep" >> $makefile_mkx

        # progress
        mklog tip " $name"
    done
    echo
fi

# make targets with user-makefile or mkx-makefile in $makefile
make="make -f $makefile $makeflags $cmdline $targets"
mklog debug "make command:[$make]"
eval $make
if [ $? -ne 0 ] ; then
    mklog error "make fail, make command:[$make]"
    exit 1
fi

# post make
cmd="`mkm get config post-make`"
mklog debug "post-make:[$cmd]"
pwd="`pwd`"
cd "$makedir"
eval "$cmd"
cd "$pwd"
