# linux-rockchip

Custom Linux kernel builds for **Rockchip RK35xx series SoCs** (RK356x, RK3576, RK3588).

This repository provides pre-built Debian kernel packages based on mainline Linux with Rockchip-specific patches applied for improved hardware support.

<br/>

## Features
- Based on recent mainline Linux kernels (currently **7.0.x** series).
- Collabora and community patches for Rockchip enhancements (GPU, display, PCIe, USB, networking, etc.).
- Built for **arm64** architecture.
- Debian `.deb` packages ready for installation on Debian-based systems (e.g., via `dpkg -i`).

<br/>

## Supported Hardware
Focused on the RK35xx family:
- **RK3566/RK3568** (e.g., ODROID-M1, NanoPi R5S/R5C, Radxa E25)
- **RK3576** (e.g., ArmSom Sige5, Luckfox Omni3576, NanoPi M5)
- **RK3588/RK3588s** (e.g., ROCK 5B, Orange Pi 5/Plus, NanoPC T6)

<br/>

## Releases
Pre-built kernel packages are available in [Releases](https://github.com/inindev/linux-rockchip/releases).

Download the appropriate `linux-image-*-arm64.deb` (and headers if needed) for your board.

<br/>

## Installation
On a running Debian arm64 system (e.g., from images built with [inindev/debian-image](https://github.com/inindev/debian-image)):

```bash
sudo dpkg -i linux-image-*-arm64.deb
sudo reboot
```

<br/>

## Building from Source
The build system downloads, patches, configures, and compiles the kernel on a native arm64 Linux host.

Prerequisites are checked automatically. To build:
```bash
git clone https://github.com/inindev/linux-rockchip.git
cd linux-rockchip
screen (or tmux)
make
```

The resulting `.deb` packages will be placed in the project directory.

<br/>

## Related Projects
- [inindev/debian-image](https://github.com/inindev/debian-image) -- Debian images that use this kernel.
- [inindev/uboot-rockchip](https://github.com/inindev/uboot-rockchip) -- Matching u-boot binaries.

<br/>

## License
GNU General Public License v3.0 (GPL-3.0) -- see [LICENSE](LICENSE) file.
