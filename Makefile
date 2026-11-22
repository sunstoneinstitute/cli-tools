BIN        := bin
GO_TOOLS    := $(notdir $(wildcard go/cmd/*))
SWIFT_TOOLS := $(notdir $(wildcard swift/Sources/*))
DARWIN     := $(filter Darwin,$(shell uname -s))
SWIFT_FLAGS ?=

ifneq ($(filter $(GO_TOOLS),$(SWIFT_TOOLS)),)
$(error tool name used in both go/ and swift/: $(filter $(GO_TOOLS),$(SWIFT_TOOLS)))
endif

.PHONY: all build go swift test test-go test-swift clean

all: build
build: go $(if $(DARWIN),swift)
test: test-go $(if $(DARWIN),test-swift)

go:
ifneq ($(GO_TOOLS),)
	@mkdir -p $(BIN)
	cd go && go build -o ../$(BIN)/ ./cmd/...
endif

swift:
ifneq ($(SWIFT_TOOLS),)
	@mkdir -p $(BIN)
	swift build -c release --package-path swift $(SWIFT_FLAGS)
	cd "$$(swift build -c release --package-path swift $(SWIFT_FLAGS) --show-bin-path)" && cp $(SWIFT_TOOLS) $(CURDIR)/$(BIN)/
endif

test-go:
ifneq ($(GO_TOOLS),)
	cd go && go vet ./... && go test ./...
endif

test-swift:
ifneq ($(wildcard swift/Tests/*Tests),)
	swift test --package-path swift
endif

clean:
	rm -rf $(BIN) swift/.build
