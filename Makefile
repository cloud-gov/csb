build:
	PAK_BUILD_CACHE_PATH=/tmp/pak-build-cache cloud-service-broker pak build brokerpaks/cg-smtp

run: build
	# Load environment variables from secrets.env, scoped to this command only.
	@bash -c 'env $$(cat secrets.env | xargs) cloud-service-broker serve'

watch:
	find . | grep -E '\.env|\.tf|\.yml' | entr -r make run

clean:
	rm -r /tmp/pak-build-cache
	rm *.brokerpak

run-docproxy:
	find docproxy | entr -r go run ./docproxy/.
