SHELL := /bin/bash

DESCRIBE           := $(shell git describe --match "v*" --always --tags)
DESCRIBE_PARTS     := $(subst -, ,$(DESCRIBE))

VERSION_TAG        := $(word 1,$(DESCRIBE_PARTS))
COMMITS_SINCE_TAG  := $(word 2,$(DESCRIBE_PARTS))

VERSION            := $(subst v,,$(VERSION_TAG))
VERSION_PARTS      := $(subst ., ,$(VERSION))

# 添加默认值，避免非数字导致算术错误
MAJOR              := $(or $(word 1,$(VERSION_PARTS)),0)
MINOR              := $(or $(word 2,$(VERSION_PARTS)),0)
MICRO              := $(or $(word 3,$(VERSION_PARTS)),0)

NEXT_MAJOR         := $(shell echo $$(($(MAJOR)+1)))
NEXT_MINOR         := $(shell echo $$(($(MINOR)+1)))
NEXT_MICRO         := $(shell echo $$(($(MICRO)+1)))

ifeq ($(strip $(COMMITS_SINCE_TAG)),)
CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(MICRO)
CURRENT_VERSION_MINOR := $(CURRENT_VERSION_MICRO)
CURRENT_VERSION_MAJOR := $(CURRENT_VERSION_MICRO)
else
CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(NEXT_MICRO)
CURRENT_VERSION_MINOR := $(MAJOR).$(NEXT_MINOR).0
CURRENT_VERSION_MAJOR := $(NEXT_MAJOR).0.0
endif

DATE                = $(shell date +'%d.%m.%Y')
TIME                = $(shell date +'%H:%M:%S')
COMMIT             := $(shell git rev-parse HEAD)
AUTHOR             := $(firstword $(subst @, ,$(shell git show --format="%aE" $(COMMIT))))
BRANCH_NAME        := $(shell git rev-parse --abbrev-ref HEAD)

TAG_MESSAGE         = "$(TIME) $(DATE) $(AUTHOR) $(BRANCH_NAME)"
COMMIT_MESSAGE     := $(shell git log --format=%B -n 1 $(COMMIT))

CURRENT_TAG_MICRO  := "v$(CURRENT_VERSION_MICRO)"
CURRENT_TAG_MINOR  := "v$(CURRENT_VERSION_MINOR)"
CURRENT_TAG_MAJOR  := "v$(CURRENT_VERSION_MAJOR)"

# Determine KERNEL and ARCH
UNAME_S:=$(shell uname -s)
UNAME_M:=$(shell uname -m)
ifeq ($(UNAME_S),Linux)
KERNEL:=linux
else ifeq ($(UNAME_S),Darwin)
KERNEL:=darwin
endif

ifeq ($(UNAME_M),x86_64)
ARCH=amd64
else ifeq ($(UNAME_M),arm64)
ARCH:=arm64
endif

.PHONY: build info fmt vet test clean install acctest local-dev-install

all: build

info:
	@echo "Global info"
	@echo "$(KERNEL)"
	@echo "$(ARCH)"
	
fmt:
	@echo " -> checking code style"
	@! gofmt -d $(shell find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'

vet:
	@echo " -> vetting code"
	@go vet ./...

test:
	@echo " -> testing code"
	@go test -v ./...

build: clean
	@echo " -> Building"
	mkdir -p bin
	CGO_ENABLED=0 go build -trimpath -o bin/terraform-provider-bve
	@echo "Built terraform-provider-bve"

# to run only certain tests, run something of the form:  make acctest TESTARGS='-run=TestAccBveVmQemu_DiskSlot'
acctest: build
	TF_ACC=1 go test ./bve $(TESTARGS)

install: build
	cp bin/terraform-provider-bve $$GOPATH/bin/terraform-provider-bve

local-dev-install: build
	@echo "Building this release $(CURRENT_VERSION_MICRO) on $(KERNEL)/$(ARCH)"
	rm -rf ~/.terraform.d/plugins/localhost/yourname/bve  # 替换 yourname 为您的用户名或组织名
	mkdir -p ~/.terraform.d/plugins/localhost/yourname/bve/$(MAJOR).$(MINOR).$(NEXT_MICRO)/$(KERNEL)_$(ARCH)/
	cp bin/terraform-provider-bve ~/.terraform.d/plugins/localhost/yourname/bve/$(MAJOR).$(MINOR).$(NEXT_MICRO)/$(KERNEL)_$(ARCH)/

clean:
	@echo " -> Cleaning"
	rm -rf bin/  # 只清理 bin/ 目录
	# @git clean -f -d  # 注释掉，避免删除源代码目录如 bve/
