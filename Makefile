.DEFAULT_GOAL := all
.PHONY: dist cli docker test universe

# Note: $(CURDIR) is the current *working* directory
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TOOLS_DIR := $(ROOT_DIR)/bin/dcos-commons-tools

dist:
	bin/dist.sh

docker: dist
	bin/docker.sh

cli:
	$(MAKE) --directory=cli

universe: cli
	bin/universe.sh

test:
	bin/test.sh
