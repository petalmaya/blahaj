# blahaj &nbsp; [![bluebuild build badge](https://github.com/petalmaya/blahaj/actions/workflows/build.yml/badge.svg)](https://github.com/petalmaya/blahaj/actions/workflows/build.yml)

My personal [uBlue](https://universal-blue.org/)/[BlueBuild](https://blue-build.org/) image.

Same idea as [bluefin](https://github.com/ublue-os/bluefin) - an
opinionated, batteries-included atomic Fedora image with Homebrew and
Flatpak front and center - but swapping GNOME out for
[niri](https://github.com/YaLTeR/niri) + [quickshell](https://quickshell.outfoxxed.me/),
running [kurukurubar](https://github.com/petalmaya/flutterquick) as the
shell/bar/launcher/lock-screen/greeter.

- **Base:** `ghcr.io/ublue-os/base-main` (no DE, since niri+quickshell
  fill that role entirely here)
- **Compositor:** niri, default config at `/etc/niri/config.kdl`
- **Shell:** quickshell running kurukurubar
  ([petalmaya/flutterquick](https://github.com/petalmaya/flutterquick)),
  vendored on-image at `/usr/share/quickshell/kurukurubar`
- **Greeter:** greetd -> niri -> kurukurubar's `greeter.qml`
- **Wallpaper/greeter background:** `/usr/share/backgrounds/blahaj/`,
  symlinked to `~/.config/background` by default via `/etc/skel`
- **CLI tools:** Homebrew (`eza`, `bat`, `fzf`, `ripgrep`, `fd`,
  `zoxide`, `fastfetch`, `gh`, `just`, ...)
- **GUI apps:** Flatpak/Flathub by default

See `recipes/recipe.yml` for the full module list, and
`files/system/` for what actually lands on the image.

## Installation

> [!WARNING]
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/petalmaya/blahaj:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/petalmaya/blahaj:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/how-to/generate-iso/#_top). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/petalmaya/blahaj
```
