VERSION := $(shell cat VERSION)
SPECFILE = pkg/sassist.spec

all: rpm

rpm: srpm
	rpmbuild --define='_topdir ${PWD}' -ba --nodeps ${SPECFILE}

srpm: tarball
	rpmbuild --define='_topdir ${PWD}' -ts ./SOURCES/sassist-${VERSION}.tar.gz

tarball:
	mkdir -p ./SOURCES
	git archive --format=tar.gz --prefix=sassist-${VERSION}/ -o ./SOURCES/sassist-${VERSION}.tar.gz HEAD

clean:
	rm -rf SOURCES BUILD BUILDROOT RPMS SRPMS SPECS
