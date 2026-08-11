{
  description = ''
    Kuru Kuru Bar (personal fork) - standalone flake.

    Packages this repo as a `kurukurubar` binary (a thin wrapper around
    `quickshell -p <this config>`), for running on NixOS without pulling
    in the rest of the Zaphkiel flake this was originally forked out of.

    `greeter.qml` (a greetd-driven login screen, added back - see
    ARCHITECTURE.md/handoff.md) is now part of `configSrc` below, so
    `quickshell -p <configSrc>/greeter.qml` works from the built package.

    `nixosModules.greeter` now generates the `services.greetd` wiring
    (config.toml + a minimal niri/labwc-only session config) that
    `greetd-examples/` previously only documented as a manual copy-paste
    exercise - see that module's own comments for what it does and does
    NOT own. This is still lighter than upstream's `kurukuruDM` (no
    autologin, no PAM/session-picker opinions beyond what `greeter.qml`
    itself already does) - intentional, see handoff.md's most recent
    session for why the line was drawn here.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # quickshell isn't in nixpkgs proper (yet) - pull it from its own
    # flake, same as most niri/quickshell setups do.
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    quickshell,
  }: let
    forEachSystem = fn:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: fn nixpkgs.legacyPackages.${system} system);
  in {
    packages = forEachSystem (pkgs: system: let
      qs = quickshell.packages.${system}.default;

      # only the bits quickshell actually needs at runtime - keeps the
      # store path from dragging in README.md/todo.md/.git/etc, and
      # doubles as a decent "did I forget to add a new top-level dir"
      # checklist whenever the module map in ARCHITECTURE.md changes.
      configSrc = pkgs.lib.fileset.toSource {
        root = ./.;
        fileset = pkgs.lib.fileset.unions [
          ./shell.qml
          ./greeter.qml
          ./Data
          ./Layers
          ./Containers
          ./Widgets
          ./Generics
          ./Assets
          ./scripts
        ];
      };

      fontconfig = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.material-symbols
          pkgs.nerd-fonts.noto-sans-mono
          pkgs.librebarcode
        ];
      };

      qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
        pkgs.kdePackages.qtbase
        pkgs.kdePackages.qtdeclarative
        pkgs.kdePackages.qtmultimedia
      ];

      runtimePath = pkgs.lib.makeBinPath [
        pkgs.rembg
        pkgs.brightnessctl
        pkgs.power-profiles-daemon
      ];
    in {
      default = self.packages.${system}.kurukurubar;

      kurukurubar = pkgs.symlinkJoin {
        pname = "kurukurubar";
        version = qs.version or "unstable";
        paths = [qs];
        nativeBuildInputs = [pkgs.makeWrapper];

        postBuild = ''
          makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar \
            --set FONTCONFIG_FILE "${fontconfig}" \
            --set QML2_IMPORT_PATH "${qmlPath}" \
            --prefix PATH : "${runtimePath}" \
            --add-flags '-p ${configSrc}'

          # Same env as the main wrapper, just pointed at greeter.qml
          # instead - this is what greetd-examples/config.toml's
          # `command` line expects to find on PATH. Kept as a second
          # binary rather than a flag on `kurukurubar` itself so greetd's
          # config.toml doesn't need to know quickshell's flag syntax at
          # all, just a plain command.
          makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar-greeter \
            --set FONTCONFIG_FILE "${fontconfig}" \
            --set QML2_IMPORT_PATH "${qmlPath}" \
            --prefix PATH : "${runtimePath}" \
            --add-flags '-p ${configSrc}/greeter.qml'
        '';

        meta = {
          description = "Kuru Kuru Bar - Quickshell config for niri/mangowc (personal fork, includes a greetd greeter.qml)";
          mainProgram = "kurukurubar";
          platforms = pkgs.lib.platforms.linux;
        };

        passthru.config = configSrc;
      };
    });

    # NixOS module: installs the package + a `programs.kurukurubar.enable`
    # toggle. Deliberately session/greeter-agnostic - it just puts the
    # binary on PATH and (optionally) autostarts it as a niri/mangowc
    # `spawn-at-startup` style user unit; wire it into your compositor's
    # own startup config or a systemd --user unit as you prefer, same as
    # running `kurukurubar` by hand.
    nixosModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: let
      cfg = config.programs.kurukurubar;
    in {
      options.programs.kurukurubar = {
        enable = lib.mkEnableOption "Kuru Kuru Bar (Quickshell config)";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          self.packages.${pkgs.system}.kurukurubar
        ];
      };
    };

    # Optional companion module: wires `greeter.qml` into `services.greetd`.
    # Independent of `nixosModules.default` on purpose - the bar and the
    # greeter are separately useful (see CLAUDE.md's "greeter.qml is a
    # separate world from shell.qml"), so enabling one shouldn't force the
    # other.
    #
    # This owns exactly what greetd-examples/README.md's steps 4-5 used to
    # have you copy by hand: config.toml's `[default_session]` and a
    # greeter-only niri/labwc config that does nothing but
    # `spawn-at-startup`/autostart `kurukurubar-greeter`. It deliberately
    # does NOT own: the `greeter` user (greetd's own package/module already
    # provisions one), wallpaper/config seeding for that user (still the
    # manual `sudo -u greeter quickshell ipc call config setWallpaper ...`
    # step in greetd-examples/README.md - too host-specific, i.e. *which*
    # wallpaper, to guess at here), or picking niri vs. labwc for you.
    nixosModules.greeter = {
      lib,
      pkgs,
      config,
      ...
    }: let
      cfg = config.programs.kurukurubar.greeter;
      greeterBin = "${self.packages.${pkgs.system}.kurukurubar}/bin/kurukurubar-greeter";

      niriGreeterConf = pkgs.writeText "niri-greeter.kdl" ''
        // Generated by nixosModules.greeter - greeter-session-only config,
        // NOT your real ~/.config/niri/config.kdl. See flake.nix.
        spawn-at-startup "${greeterBin}"
        input {
        }
      '';

      labwcGreeterConf = pkgs.runCommand "labwc-greeter-dir" {} ''
        mkdir -p $out
        cat > $out/autostart <<EOF
        ${greeterBin} &
        EOF
      '';
    in {
      options.programs.kurukurubar.greeter = {
        enable = lib.mkEnableOption "greetd session running kurukurubar's greeter.qml";
        compositor = lib.mkOption {
          type = lib.types.enum ["niri" "labwc"];
          default = "niri";
          description = "Which compositor runs the greeter session itself. Independent of what your real post-login session uses.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.greetd = {
          enable = true;
          settings.terminal.vt = 1;
          settings.default_session = {
            user = "greeter";
            command =
              if cfg.compositor == "niri"
              then "${lib.getExe pkgs.niri} --config ${niriGreeterConf}"
              else "${lib.getExe' pkgs.labwc "labwc"} -C ${labwcGreeterConf}";
          };
        };
      };
    };

    devShells = forEachSystem (pkgs: system: {
      default = pkgs.mkShell {
        packages = [
          quickshell.packages.${system}.default
          pkgs.qtcreator
        ];
      };
    });
  };
}
