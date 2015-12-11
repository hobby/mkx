#!/bin/bash
# vim:ts=4:sw=4:expandtab

############################################################
# NAME
#     mk - a toy for make targets.
#
# SYNOPSIS
#     mk
#     mk [ -f makefile ] [ -C directory ] [ targets ] ...
#
#     debug=on mk ...
#
# AUTHORS
#     neiku project <ku7d@qq.com>
#
# VERSION
#     2015/12/11: 支持目录递归、编译前/后自定义命令
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

# make targets
make $* $targets
if [ $? -ne 0 ] ; then
    mklog error "make fail, make args:[$* $targets]"
    exit 1
fi

# post make
cmd="`mkm get config post-make`"
mklog debug "post-make:[$cmd]"
pwd="`pwd`"
cd "$makedir"
eval "$cmd"
cd "$pwd"
