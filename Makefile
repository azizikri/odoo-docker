# Makefile for Odoo docker workflow

# Load environment from .env if present and export to subprocesses
ifneq (,$(wildcard .env))
include .env
export
endif

# Defaults if not provided
POSTGRES_DB ?= odoo
POSTGRES_USER ?= odoo
POSTGRES_PASSWORD ?= odoo
ODOO_VERSION ?= 17.0

DC ?= docker compose

.PHONY: help setup up build

help:
	@echo "Targets:"
	@echo "  setup  - Pull/build images and initialize DB (base module)."
	@echo "  up     - Start services in background."
	@echo "  build  - Build/pull images."

# Build/pull images (safe even when using prebuilt images)
build:
	$(DC) build --pull || $(DC) pull

# Initialize the database with base module and no demo data
setup: build
	$(DC) run --rm odoo \
	  -i base --without-demo=all --stop-after-init \
	  --db_host=db --db_user=$(POSTGRES_USER) --db_password=$(POSTGRES_PASSWORD) -d $(POSTGRES_DB)

# Bring the stack up
up:
	$(DC) up -d
