build:
	@scripts/build_and_push.sh

build_test:
	@DRY_RUN=1 scripts/build_and_push.sh

.PHONY: build