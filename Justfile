# Cotty — Swift terminal emulator powered by libghostty-vt
#
# Prerequisites: `direnv allow` (or `nix develop`), then:
#   just build-libghostty   # one-time (or after ghostty updates)
#   just build              # compile Swift sources
#   just run                # compile + run

_ghostty_version := env_var_or_default("GHOSTTY_VERSION", "1.3.1")

# Build libghostty-vt into .build/ghostty-prefix
build-libghostty:
    @echo "→ Building libghostty-vt (ghostty {{_ghostty_version}})"
    cotty-build-libghostty

# Compile the Swift project (debug)
build:
    cotty-swift build

# Compile in release mode
release:
    cotty-swift build -c release

# Build and run the cotty binary
run:
    cotty-swift run

# Run release build
run-release:
    cotty-swift run -c release

# Remove build artifacts
clean:
    rm -rf .build/swift-cotty

# Remove all build artifacts including libghostty
distclean: clean
    rm -rf .build/ghostty-prefix .build/ghostty-src

# Default target
default: build
