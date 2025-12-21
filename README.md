# linux-rockchip

Custom Linux kernel builds for **Rockchip RK35xx series SoCs** (primarily RK356x, RK3576, RK3588).

This repository provides pre-built Debian kernel packages based on mainline Linux with Rockchip-specific patches applied for improved hardware support.

<br/>

## Features
- Based on recent mainline Linux kernels (currently **6.18.x** series).
- Patches from the `patches/` directory for Rockchip enhancements (e.g., better Mali GPU, display, networking, etc.).
- Built for **arm64** architecture.
- Debian `.deb` packages ready for installation on Debian-based systems (e.g., via `dpkg -i`).

<br/>

## Releases
Pre-built kernel packages are available in [Releases](https://github.com/inindev/linux-rockchip/releases):

- **v6.18.2** (Dec 19, 2025) – linux-image-*.deb for 6.18.2
- **v6.18.1** (Dec 14, 2025)
- **v6.18** (Dec 1, 2025)
- Older: v6.16, v6.15, etc.

Download the appropriate `linux-image-*-arm64.deb` (and headers if needed) for your board.

<br/>

## Installation
On a running Debian arm64 system (e.g., from images built with [inindev/debian-image](https://github.com/inindev/debian-image)):

```bash
wget https://github.com/inindev/linux-rockchip/releases/download/v6.18.2/linux-image-6.18.2-arm64.deb
sudo dpkg -i linux-image-6.18.2-arm64.deb
sudo reboot
```

For newer RK3576 boards, this kernel provides enhanced support over stock Debian kernels.

<br/>

## Supported Hardware
Focused on RK35xx family:
- RK3566/RK3568 (e.g., ODROID-M1, NanoPi R5S/R5C, Radxa E25)
- RK3576 (e.g., Armsom Sige5, Luckfox Omni3576, NanoPi M5)
- RK3588/RK3588s (e.g., ROCK 5B, Orange Pi 5/Plus, NanoPC T6)

<br/>

## Building from Source
The repository contains kernel sources and patches. To build your own using arm64 Linux:

1. Clone the repo:
   ```bash
   git clone https://github.com/inindev/linux-rockchip.git
   cd linux-rockchip
   ```

2. Build:
   ```bash
   make -j$(nproc)
   ```

<br/>

## Related Projects
- [inindev/debian-image](https://github.com/inindev/debian-image) – Debian images that use this kernel.
- [inindev/uboot-rockchip](https://github.com/inindev/uboot-rockchip) – Matching u-boot binaries.

<br/>

## License
GNU General Public License v3.0 (GPL-3.0) – see [LICENSE](LICENSE) file.
