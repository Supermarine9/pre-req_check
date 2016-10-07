#!/usr/bin/env bash

################################################################################
#                   Oracle Database Pre-Requisite Checker
#              Pre-Requisite Checks made easy for Linux & Solaris
#
#                                 Version 1.0
#
# Copyright (C) 2016  Wesley Dewsnup
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or see
# http://www.gnu.org/licenses/
################################################################################

################################################################################
# Declare Variables #
#####################
OUTPUT_FILE=prereq_results.txt
TMP_FILE=/tmp/prereq_packages
DEFAULT_PREREQ=12cR1
DEFAULT_YES=yes
DEFAULT_NO=no
BOLD=$( tput bold )
NORMAL=$( tput sgr0 )
RED='\033[0;31m'
NC='\033[0m' # No Color
HOME=$( dirname $( readlink -f "$0" ) )
################################################################################

################################################################################
# MAIN FUNCTIONS #
##################

# Header
########
header()
{
  clear
  TITLE="Oracle Database Pre-Requisite Checker"
  DESCRIPTION="Pre-Requisite Checks made easy for Linux & Solaris"
  VERSION="Version 1.0"
  printf "${BOLD}%*s${NORMAL}\n" $(( ( $(echo $TITLE | wc -c ) + 80 ) / 2 )) "$TITLE"
  printf "${BOLD}%*s${NORMAL}\n" $(( ( $(echo $DESCRIPTION | wc -c ) + 80 ) / 2 )) "$DESCRIPTION"
  echo
  printf "${BOLD}%*s${NORMAL}\n" $(( ( $(echo $VERSION | wc -c ) + 80 ) / 2 )) "$VERSION"
  echo -e "\n"
}

# Copyright
###########
copyright()
{
read -d '' COPYRIGHT <<- EOF
${BOLD}Copyright (C) 2016  Wesley Dewsnup${NORMAL}

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but ${BOLD}WITHOUT ANY WARRANTY${NORMAL}; without even the implied warranty of
${BOLD}MERCHANTABILITY${NORMAL} or ${BOLD}FITNESS FOR A PARTICULAR PURPOSE${NORMAL}.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or see
http://www.gnu.org/licenses/
EOF
  echo -e "$COPYRIGHT\n"
}

# Accept licence
################
accept()
{
  while [[ $ACCEPT != @([cC]) ]]; do
    header
    copyright
    read -e -p "'L' view full license, 'Q' to quit, or 'Enter' to continue: " ACCEPT
    ACCEPT=${ACCEPT:-C}
    if [[ $ACCEPT =~ ^([lL])$ ]]; then
      less $HOME/LICENSE
    elif [[ $ACCEPT =~ ^([qQ])$ ]]; then
      clear
      exit 1
    fi
  done
}

# System Check
##############
system()
{
  header > $OUTPUT_FILE
  if [ -f /etc/oracle-release ]; then
    OPERATING_SYSTEM=oel
    VERSION=`cat /etc/oracle-release | cut -d" " -f5`
    MAJOR_VERSION=`echo ${VERSION} | cut -d. -f1` 
  elif [ -f /etc/redhat-release ]; then
    OPERATING_SYSTEM=rhel
    VERSION=`cat /etc/redhat-release | cut -d" " -f7`
    MAJOR_VERSION=`echo ${VERSION} | cut -d. -f1`
  elif [ -f /etc/release ] && grep "Oracle Solaris 1[0|1]" /etc/release > /dev/null; then
    OPERATING_SYSTEM=solaris
    DISTRO=/etc/release
    # You'll have to come up with how Solaris does versions
  else
    echo -e "\n${BOLD}No supported Operating System found.${NORMAL}\n"
    exit 1
  fi
}

# Packages Check
################
packages()
{
  touch ${TMP_FILE}
  
  case ${OPERATING_SYSTEM} in
    "oel"|"rhel")
      case ${MAJOR_VERSION} in
        7) PACKAGELIST="binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel libXi libXtst make sysstat"
          ;;
        6) PACKAGELIST="binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel libXext libXtst libX11 libXau libxcb libXi make sysstat"
          ;;
        5) PACKAGELIST="binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel elfutils-libelf-devel-static gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgcc libgomp libstdc++ libstdc++-devel make sysstat"
          ;;
        *)
          echo "Major Version ${MAJOR_VERSION} of ${DISTRO} not found."
          exit 1
          ;;
      esac
      for package in ${PACKAGELIST}
      do
        rpm -q --queryformat "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH} (%{VENDOR})\n" ${package} >> ${TMP_FILE}
      done
      echo -e '\n\n================================\nINSTALLED PRE-REQUISITE PACKAGES\n================================\n' >> ${OUTPUT_FILE}
      grep "(" ${TMP_FILE} >> ${OUTPUT_FILE}
      echo -e '\n\n==============================\nMISSING PRE_REQUISITE PACKAGES\n==============================\n' >> ${OUTPUT_FILE}
      grep ^package ${TMP_FILE} >> ${OUTPUT_FILE}
      ;;

    "sles")
      # Do SuSE packages here.
      ;;

    "solaris")
      # Check Solaris packages here.
      ;;

    *)
      echo "Operating System not suppored"
      exit 1
      ;;

  esac

  cat ${OUTPUT_FILE}
  rm -f ${TMP_FILE}
  unset packages
}

################################################################################

################################################################################
# PROGRAM LOGIC #
#################
accept  # Runs the accept copyright function
system  # Runs the system check function
packages  # Runs the packages check function
################################################################################
exit 0  # Exit cleanly
