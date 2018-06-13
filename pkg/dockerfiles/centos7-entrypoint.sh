#!/bin/sh

./pkg/mk-rel-rpm.sh
cp $BUILD_DIR/_builddir/noarch/*.rpm $OUTPUT_DIR
