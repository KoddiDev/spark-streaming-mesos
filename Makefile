docker:
	bin/make-docker.sh

test:
	bin/test.sh

dist:
	bin/dist.sh

.PHONY: docker universe test dist
