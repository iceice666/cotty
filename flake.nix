{
  description = "Cotty Swift terminal emulator development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ghostty-src = {
      url = "github:ghostty-org/ghostty/v1.3.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ghostty-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
        ghosttyVersion = "1.3.1";
        ghosttyPrefix = "$PWD/.build/ghostty-prefix";

        cottySwift = pkgs.writeShellScriptBin "cotty-swift" ''
          set -euo pipefail

          if [ -x /usr/bin/xcode-select ] && [ -x /usr/bin/xcrun ]; then
            export DEVELOPER_DIR="$(env -u DEVELOPER_DIR /usr/bin/xcode-select -p)"
            export SDKROOT="$(env -u SDKROOT -u NIX_CFLAGS_COMPILE -u NIX_LDFLAGS -u DEVELOPER_DIR /usr/bin/xcrun --sdk macosx --show-sdk-path)"
            export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
          fi

          exec swift "$@"
        '';

        buildLibghostty = pkgs.writeShellScriptBin "cotty-build-libghostty" ''
          set -euo pipefail

          prefix="$PWD/.build/ghostty-prefix"
          work="$PWD/.build/ghostty-src"

          mkdir -p "$PWD/.build"
          rm -rf "$work"
          cp -R ${ghostty-src} "$work"
          chmod -R u+w "$work"
          (cd "$work" && ${pkgs.python3}/bin/python3 ${./nix/patch-ghostty-build.py})
          if [ -x /usr/bin/xcode-select ] && [ -x /usr/bin/xcrun ]; then
            export DEVELOPER_DIR="$(/usr/bin/xcode-select -p)"
            export SDKROOT="$(env -u SDKROOT -u NIX_CFLAGS_COMPILE -u NIX_LDFLAGS -u DEVELOPER_DIR /usr/bin/xcrun --sdk macosx --show-sdk-path)"
          fi

          cd "$work"
          zig build lib-vt \
            --prefix "$prefix" \
            -Dversion-string=${ghosttyVersion} \
            -Dapp-runtime=none \
            -Doptimize=Debug \
            -Dcpu=baseline \
            ${lib.optionalString (system == "aarch64-darwin") "-Dtarget=aarch64-macos"} \
            ${lib.optionalString (system == "x86_64-darwin") "-Dtarget=x86_64-macos"} \
            ${lib.optionalString isDarwin "-Demit-xcframework=false -Demit-macos-app=false"}

          echo "libghostty-vt installed under $prefix"
          echo "PKG_CONFIG_PATH=$prefix/share/pkgconfig"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.pkg-config
            pkgs.zig_0_15
            buildLibghostty
            cottySwift
            pkgs.just
          ] ++ lib.optionals (!isDarwin) [
            pkgs.swift
          ];

          shellHook = ''
            export GHOSTTY_SOURCE=${ghostty-src}
            export GHOSTTY_VERSION=${ghosttyVersion}
            export GHOSTTY_PREFIX="${ghosttyPrefix}"
            export PKG_CONFIG_PATH="$GHOSTTY_PREFIX/share/pkgconfig:''${PKG_CONFIG_PATH:-}"
            export LIBRARY_PATH="$GHOSTTY_PREFIX/lib:''${LIBRARY_PATH:-}"
            export CPATH="$GHOSTTY_PREFIX/include:''${CPATH:-}"
            export DYLD_LIBRARY_PATH="$GHOSTTY_PREFIX/lib:''${DYLD_LIBRARY_PATH:-}"
            export LD_LIBRARY_PATH="$GHOSTTY_PREFIX/lib:''${LD_LIBRARY_PATH:-}"
            if [ -x /usr/bin/xcode-select ] && [ -x /usr/bin/xcrun ]; then
              export DEVELOPER_DIR="$(/usr/bin/xcode-select -p)"
              export SDKROOT="$(env -u SDKROOT -u NIX_CFLAGS_COMPILE -u NIX_LDFLAGS -u DEVELOPER_DIR /usr/bin/xcrun --sdk macosx --show-sdk-path)"
            fi
            export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

            if ! command -v swift >/dev/null 2>&1; then
              echo "Swift is not in PATH. On Darwin, install/use Xcode or Command Line Tools."
            fi

            if [ ! -f "$GHOSTTY_PREFIX/share/pkgconfig/libghostty-vt.pc" ]; then
              echo "libghostty-vt is not built yet. Run: cotty-build-libghostty"
            fi
          '';
        };
      });
}
