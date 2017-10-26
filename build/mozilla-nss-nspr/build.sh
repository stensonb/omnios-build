#!/usr/bin/bash
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
# Copyright 2017 OmniTI Computer Consulting, Inc.  All rights reserved.
# Use is subject to license terms.
#
# Load support functions
. ../../lib/functions.sh

PROG=nss
VER=3.33
# Include NSPR version since we're downloading a combined tarball.
NSPRVER=4.17
# But set BUILDDIR to just be the NSS version.
BUILDDIR=$PROG-$VER
VERHUMAN=$VER
PKG=$PROG ##IGNORE##
SUMMARY="Not the real summary"
DESC="$SUMMARY"

# NOTE: These are generated by uname and build variables.
# CHECK THESE WHEN THINGS CHANGE!
DIST32=SunOS5.11_i86pc_gcc_OPT.OBJ
DIST64=SunOS5.11_i86pc_gcc_64_OPT.OBJ

BUILD_DEPENDS_IPS="library/nspr/header-nspr"

MAKE_OPTS="
    BUILD_OPT=1
    NS_USE_GCC=1
    NO_MDUPDATE=1
    NSDISTMODE=copy
    XCFLAGS=-g
"

NSS_LIBS="libfreebl3.so libnss3.so
	libnssckbi.so libnssdbm3.so
	libnssutil3.so libsmime3.so
	libsoftokn3.so libssl3.so"
NSPR_LIBS="libnspr4.so libplc4.so libplds4.so"

# Variables that switch between NSS and NSPR
TGT_LIBS=$NSS_LIBS
PC_FILE=nss.pc
LOCAL_MOG_FILE=nss-local.mog

make_clean() {
    # Assume PWD == top-level with nss & nspr subdirs.
    /bin/rm -rf dist
    cd nss
    logcmd gmake $MAKE_OPTS nss_clean_all || logerr "Can't make clean"
    cd ..
}

configure32() {
    # Get the install/prototype path out of the way now.
    logcmd mkdir -p $DESTDIR/usr/lib/mps || \
	logerr "Failed to create NSS install directory."
}

make_prog32() {
    logmsg "Making libraries (32)"
    # Assume PWD == top-level with nss & nspr subdirs.
    cd nss
    logcmd gmake $MAKE_OPTS nss_build_all || logerr "build failed"
    cd ..
}
make_install32() {
    logmsg "Installing libraries (32)"
    for lib in $TGT_LIBS
    do
        logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST32/lib/$lib \
	    $DESTDIR/usr/lib/mps/$lib
    done
    logmsg "Installing headers"
    logcmd mkdir -p $DESTDIR/usr/include/mps || \
	logerr "Failed to create NSS header install directory."
    logcmd cp $TMPDIR/$BUILDDIR/dist/public/nss/* $DESTDIR/usr/include/mps/
    logcmd cp $TMPDIR/$BUILDDIR/dist/public/dbm/* $DESTDIR/usr/include/mps/

    # Save 32-bit NSPR dist off for NSPR build.
    mkdir /tmp/nspr-save.$$
    for lib in $NSPR_LIBS
    do
	logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST32/lib/$lib /tmp/nspr-save.$$
    done
    cp $TMPDIR/$BUILDDIR/nspr/$DIST32/config/nspr.pc /tmp/nspr-save.$$
}

configure64() {
    # Get the install/prototype path out of the way now.
    logcmd mkdir -p $DESTDIR/usr/lib/mps/amd64 || \
	logerr "Failed to create NSS install directory."
}

make_prog64() {
    logmsg "Making libraries (64)"
    # Assume PWD == top-level with nss & nspr subdirs.
    cd nss
    logcmd gmake $MAKE_OPTS USE_64=1 nss_build_all || logerr "build failed"
    cd ..
}
make_install64() {
    logmsg "Installing libraries (64)"
    for lib in $TGT_LIBS
    do
        logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST64/lib/$lib \
	    $DESTDIR/usr/lib/mps/amd64/$lib
    done
}
secv1_links() {
    logcmd ln -s amd64 $DESTDIR/usr/lib/mps/64
    logcmd mkdir -p $DESTDIR/usr/lib/mps/secv1/amd64
    logcmd ln -s amd64 $DESTDIR/usr/lib/mps/secv1/64
    logcmd mkdir -p $DESTDIR/usr/lib/pkgconfig
    logcmd cp $SRCDIR/files/$PC_FILE $DESTDIR/usr/lib/pkgconfig
    for lib in $TGT_LIBS
    do
        ln -s ../../amd64/$lib $DESTDIR/usr/lib/mps/secv1/amd64/$lib
        ln -s ../$lib $DESTDIR/usr/lib/mps/secv1/$lib
    done
}

init
# Download combined NSS & NSPR tarball.
download_source $PROG $PROG "$VER-with-nspr-$NSPRVER"
patch_source
prep_build
build
secv1_links

PKG=system/library/mozilla-nss/header-nss
SUMMARY="Network Security Services Headers"
DESC="$SUMMARY"
make_package header-nss.mog

DEPENDS_IPS="SUNWcs system/library/gcc-5-runtime system/library
	library/nspr database/sqlite-3"
PKG=system/library/mozilla-nss
SUMMARY="Network Security Services Libraries"
DESC="$SUMMARY"
make_package nss.mog

# This cleans up NSS.
clean_up

# Switch variables & populate other proto area.
VER=$NSPRVER
TGT_LIBS=$NSPR_LIBS
PC_FILE=nspr.pc
LOCAL_MOG_FILE=nspr-local.mog
DESTDIR=`echo $DESTDIR | sed 's/nss/nspr/g'`
prep_build
logcmd mkdir -p $DESTDIR/usr/include/mps/md || \
    logerr "Failed to create NSPR header install directory."
logcmd mkdir -p $DESTDIR/usr/include/mps/obsolete || \
    logerr "Failed to create NSPR header install directory."
logcmd mkdir -p $DESTDIR/usr/include/mps/private || \
    logerr "Failed to create NSPR header install directory."
logcmd mkdir -p $DESTDIR/usr/lib/mps/amd64 || \
    logerr "Failed to create NSPR install directory."
logcmd mkdir -p $DESTDIR/usr/lib/mps/pkgconfig || \
    logerr "Failed to create NSPR install directory."
logcmd mkdir -p $DESTDIR/usr/lib/mps/amd64/pkgconfig || \
    logerr "Failed to create NSPR install directory."
logcmd mkdir -p $DESTDIR/usr/include/mps/pkgconfig || \
    logerr "Failed to create NSPR header install directory."

make_install64
logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST64/include/*.h $DESTDIR/usr/include/mps
logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST64/include/obsolete/*.h \
    $DESTDIR/usr/include/mps/obsolete
logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST64/include/private/*.h \
    $DESTDIR/usr/include/mps/private
logcmd cp $TMPDIR/$BUILDDIR/dist/$DIST64/include/md/* \
    $DESTDIR/usr/include/mps/md
logcmd cp $TMPDIR/$BUILDDIR/nspr/$DIST64/config/nspr.pc \
    $DESTDIR/usr/lib/mps/amd64/pkgconfig
# Restore 32-bit NSPR libraries.
logcmd cp /tmp/nspr-save.$$/nspr.pc $DESTDIR/usr/lib/mps/pkgconfig/nspr.pc
logcmd cp /tmp/nspr-save.$$/*.so $DESTDIR/usr/lib/mps || \
    logerr "32-bit NSPR library installation failure"
logcmd rm -rf /tmp/nspr-save.$$
secv1_links

PKG=library/nspr/header-nspr
SUMMARY="Netscape Portable Runtime Headers"
DESC="$SUMMARY"
make_package header-nspr.mog

DEPENDS_IPS="SUNWcs system/library/gcc-5-runtime system/library"
PKG=library/nspr
SUMMARY="Netscape Portable Runtime"
DESC="$SUMMARY"
make_package nspr.mog

# This cleans up NSPR.
clean_up

# Vim hints
# vim:ts=4:sw=4:et:
