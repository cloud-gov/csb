BROKERPAK ?= aws-ses
BROKER_WORKDIR := $(CURDIR)
PAK_TARGET_FLAGS :=
OPENBAO_DIR := $(CURDIR)/.local/openbao
OPENBAO_ENV = env -i PATH="$$PATH" bash -ec 'umask 077; set -a; . "$$1"; shift; exec "$$@"' bash "$(OPENBAO_DIR)/secrets.env" \
	env CSB_LISTENER_HOST=127.0.0.1 DB_TYPE=sqlite3 DB_PATH=csb-env.sqlite ENCRYPTION_ENABLED=true \
	BP_OPENBAO_ROOT_STORE_PREFIX="file://$(OPENBAO_DIR)/native/private" \
	BROKERPAK_UPDATES_ENABLED=false TERRAFORM_UPGRADES_ENABLED=false

ifeq ($(BROKERPAK),openbao-stack)
BROKER_WORKDIR := $(OPENBAO_DIR)/native
PAK_TARGET_FLAGS := --target current
endif

.PHONY: build run watch clean
build:
ifeq ($(BROKERPAK),openbao-stack)
	umask 077 && mkdir -p "$(BROKER_WORKDIR)"
endif
	cd "$(BROKER_WORKDIR)" && PAK_BUILD_CACHE_PATH=/tmp/pak-build-cache cloud-service-broker pak build $(PAK_TARGET_FLAGS) "$(CURDIR)/brokerpaks/$(BROKERPAK)"

run: build
ifeq ($(BROKERPAK),openbao-stack)
	cd "$(BROKER_WORKDIR)" && $(OPENBAO_ENV) cloud-service-byroker serve
else
	# Load environment variables from secrets.env, scoped to this command only.
	@bash -c 'env $$(cat secrets.env | xargs) cloud-service-broker serve'
endif

watch:
	find . | grep -E '\.env|\.tf|\.yml' | entr -r make run BROKERPAK="$(BROKERPAK)"

clean:
	rm -r /tmp/pak-build-cache
	rm *.brokerpak

.PHONY: openbao-build openbao-up openbao-test openbao-smoke openbao-probe openbao-catalog
openbao-build:
	$(MAKE) build BROKERPAK=openbao-stack

openbao-up:
	$(MAKE) run BROKERPAK=openbao-stack

openbao-test:
	python3 brokerpaks/openbao-stack/tools/run_unit.python3

openbao-smoke:
	python3 brokerpaks/openbao-stack/tests/smoke

openbao-probe:
	python3 brokerpaks/openbao-stack/tools/probe_provider.py

openbao-catalog:
	cd "$(OPENBAO_DIR)/native" && $(OPENBAO_ENV) python3 "$(CURDIR)/brokerpaks/openbao-stack/tools/show_catalog.py"
