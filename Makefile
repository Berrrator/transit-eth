VGO=go # Set to vgo if building in Go 1.10
BINARY_NAME=transiteth
BUILD_VERSION?=$(shell git rev-parse --short HEAD)
SRC_GOFILES := $(shell find . -name '*.go' -print)

.DELETE_ON_ERROR:

all: build test

test: deps
	$(VGO) test ./... -cover -coverprofile=coverage.txt -covermode=atomic

transiteth: ${SRC_GOFILES}
	$(VGO) build -o ${BINARY_NAME} -ldflags "-X main.buildDate=`date -u +\"%Y-%m-%dT%H:%M:%SZ\"` -X main.buildVersion=$(BUILD_VERSION)" -tags=prod -v ./

build: transiteth

clean: 
	$(VGO) clean
	rm -f ${BINARY_NAME}
	rm -f coverage.txt

deps:
	$(VGO) get
	$(VGO) mod tidy

install: build
	sudo cp $(BINARY_NAME) /opt/vault/plugins/

dev: build
	vault server -dev -dev-root-token-id=root -dev-plugin-dir=. &
	sleep 5
	VAULT_TOKEN=root vault secrets enable -path=transiteth -plugin-name=$(BINARY_NAME) plugin

stop:
	pkill vault || true

fmt:
	$(VGO) fmt $$($(VGO) list ./...)

.PHONY: all build clean test deps install dev stop fmt