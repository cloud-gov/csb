build:
	PAK_BUILD_CACHE_PATH=/tmp/pak-build-cache cloud-service-broker pak build brokerpaks/cg-smtp

run: build
	# Load environment variables from secrets.env, scoped to this command only.
	@bash -c 'env $$(cat secrets.env | xargs) cloud-service-broker serve'

watch:
	find . | grep -E '\.env|\.tf' | entr -r make run
