#!/bin/sh

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

# Author: djcj <djcj@gmx.de>

#set -x

#LXSS = C:\Users\<WINUSER>\AppData\Local\lxss
#/mnt/d -> D:
#/mnt -> <LXSS>\mnt
#/home -> <LXSS>\home
#/root -> <LXSS>\root
#/ -> <LXSS>\rootfs

print_usage() {
  echo "usage:"
  echo "  $0 [-w|-u|-m] path"
  echo "  $0 -h"
  echo ""
  echo "  -w  print Windows path"
  echo "  -u  print Unix path"
  echo "  -m  print Windows path with forward slashes (mixed mode)"
  echo "  -h  show this help"
  echo ""
  exit $1
}

if !(grep -q 'Microsoft' /proc/version 2>/dev/null || 
     grep -q 'Microsoft' /proc/sys/kernel/osrelease 2>/dev/null)
then
  echo "Warning: script was made for \"Bash on Windows\"" > /dev/stderr
fi

if [ -z "$1" ]; then
  print_usage 1
fi

to_unix="yes"
mixed_mode="no"

case "$1" in
  "-w") to_unix="no"; p="$2";;
  "-u") p="$2";;
  "-m") to_unix="no"; mixed_mode="yes"; p="$2";;
  "-h") print_usage 0;;
  *)    p="$1";;
esac

if [ -z "$p" ]; then
  print_usage 1
fi

p="$(echo "$p" | sed -e 's|\\\+|/|g')"
winuser="$(/mnt/c/Windows/System32/whoami.exe 2>/dev/null | tr -d '\r' | cut -d'\' -f2)"
lxss="C:/Users/$winuser/AppData/Local/lxss"

if [ "$to_unix" = "yes" ]; then
  lxss_len="$(printf "$lxss" | wc -m)"
  if [ "$(echo "$p" | head -c$lxss_len)" = "$lxss" ]; then
    lxss_cut="$(echo "$p" | cut -d'/' -f7)"
    if [ "$lxss_cut" = "home" ] || [ "$lxss_cut" = "root" ] || [ "$lxss_cut" = "mnt" ]; then
      p="$(echo "$p" | tail -c+$(($lxss_len+1)))"
    elif [ "$lxss_cut" = "rootfs" ]; then
      p="$(echo "$p" | tail -c+$(($lxss_len+8)))"
      test -n "$p" || p="/"
    fi
  fi
  if [ -n "$(echo "$p" | head -c3 | grep -e '^[A-Za-z]:$')" ] ||
     [ -n "$(echo "$p" | head -c3 | grep -e '^[A-Za-z]:/$')" ];
  then
    drive=$(echo "$p" | head -c1 | tr '[A-Z]' '[a-z]')
    append="$(echo "$p" | tail -c+3)"
    p="/mnt/${drive}${append}"
  fi
else
  if [ "$(echo "$p" | head -c1)" = "/" ]; then
    if [ -n "$(echo "$p" | head -c7 | grep -e '^/mnt/[a-z]$')" ] ||
       [ -n "$(echo "$p" | head -c7 | grep -e '^/mnt/[a-z]/$')" ];
    then
      drive=$(echo "$p" | head -c6 | tail -c1 | tr '[a-z]' '[A-Z]')
      append="$(echo "$p" | tail -c+7)"
      p="${drive}:${append}"
    else
      firstdir="$(echo "$p" | cut -d '/' -f2)"
      if [ "$firstdir" = "home" ] || [ "$firstdir" = "root" ] || [ "$firstdir" = "mnt" ]; then
        p="${lxss}${p}"
      else
        p="${lxss}/rootfs${p}"
      fi
    fi
  fi
  if [ "$mixed_mode" != "yes" ]; then
    p="$(echo "$p" | tr '/' '\\')"
  fi
fi

echo "$p"

