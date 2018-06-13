#!/bin/sh
# vim:et:ai:ts=4:sw=4:filetype=sh:tw=0:

set -x

cur_dir=$(cd $(dirname $0); pwd)

VERSION=$(cat VERSION)
cp COPYING src
mv src sassist-$VERSION
tar zcf sassist-$VERSION.tar.gz ./sassist-$VERSION

cd $cur_dir/../

umask 002

set -e

chmod -R +w _builddir ||:
rm -rf _builddir

mkdir _builddir
pushd _builddir

TOPDIR="/build/_builddir"
rpmbuild --define "_topdir $TOPDIR" \
	--define "_builddir $TOPDIR" \
	--define "_sourcedir $TOPDIR/../" \
	--define "_specdir $TOPDIR/pkg" \
	--define "_srcrpmdir $TOPDIR" \
	--define "_rpmdir $TOPDIR" \
	-ba --nodeps $TOPDIR/../pkg/sassist.spec
