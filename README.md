# msx-devbox

A complete MSX development environment packaged in Docker. Includes openMSX 21.0 emulator compiled with GCC 13, SDCC Z80 compiler, hex2bin conversion tools and browser-accessible VNC interface. Build and test MSX software without local installation hassles.

## Features

- 🎮 **openMSX 21.0** - Full-featured MSX emulator
- 🔧 **SDCC** - Small Device C Compiler for Z80
- 🛠️ **hex2bin** - Binary conversion utilities
- 🌐 **noVNC** - Browser-based VNC access (no client installation needed)
- 🐳 **Fully containerized** - Consistent development environment

## Prerequisites

- Docker
- Docker Compose

## Setup

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/msx-devbox.git
cd msx-devbox
```

### 2. Create required directories
```bash
mkdir -p roms systemroms src
```

**Directory structure:**
```
msx-devbox/
├── roms/          # Your MSX game/program ROMs (.rom, .dsk files)
├── systemroms/    # MSX BIOS ROMs (required for emulation)
├── src/           # Your development source code
├── Dockerfile
├── docker-compose.yml
└── supervisord.conf
```

### 3. Add System ROMs

You need MSX BIOS ROMs for the emulator to work. Place them in the `systemroms/` directory:

**Required files (example for MSX2):**
- `MSX.ROM` (BIOS)
- `MSX2.ROM` (MSX2 BIOS)
- `MSX2EXT.ROM` (MSX2 sub-ROM)
- `DISK.ROM` (Disk BIOS)

**Where to get system ROMs:**
- Extract from original MSX hardware (legal if you own it)
- Search for "MSX BIOS ROMs" (verify legality in your region)
- Check openMSX documentation: https://openmsx.org/manual/setup.html

### 4. Add your ROMs (optional)

Place your MSX game/software ROMs in the `roms/` directory:
```bash
cp /path/to/your/game.rom roms/
cp /path/to/your/disk.dsk roms/
```

## Usage

### Start the container
```bash
docker-compose up -d
```

### Access the emulator

Open your web browser and navigate to:
```
http://localhost:6080
```

You'll see a desktop environment with:
- **xterm** terminal (for compiling and building)
- **openMSX** emulator (if auto-started via supervisord)

### Using openMSX

**Load a ROM:**
```bash
openmsx -cart /home/dev/roms/your-game.rom
```

**Load a disk image:**
```bash
openmsx -diska /home/dev/roms/your-disk.dsk
```

**Interactive Tcl console:**
Inside openMSX, press `F10` to access the console, then:
```tcl
cart /home/dev/roms/game.rom
diska /home/dev/roms/disk.dsk
```

### Development workflow

1. **Write code** in `src/` directory (on your host machine)
2. **Compile** inside the container:
```bash
   docker exec -it openmsx bash
   cd /home/dev/src
   sdcc -mz80 your-program.c
   hex2bin your-program.hex
```
3. **Test** with openMSX in the browser

### Stop the container
```bash
docker-compose down
```

## noVNC Controls

- **Ctrl+Alt+Shift** - Opens noVNC control panel
- **Fullscreen** - Available in control panel
- **Clipboard** - Copy/paste between host and container via control panel

## Troubleshooting

### openMSX fails to start

**Error:** `Could not init MSX machine`

**Solution:** Make sure system ROMs are in `systemroms/` directory and properly named.

### Can't access noVNC

**Check if container is running:**
```bash
docker ps
```

**View logs:**
```bash
docker logs openmsx
```

### Permission issues with mounted volumes

**Fix ownership:**
```bash
sudo chown -R $(id -u):$(id -g) src/ roms/ systemroms/
```

## Advanced Configuration

### Custom openMSX settings

Edit `startup.tcl` to configure default machine type, extensions, etc:
```tcl
# Example: Auto-load specific machine
machine MSX2+
```

### Expose VNC port for native clients

Uncomment in `docker-compose.yml`:
```yaml
ports:
  - "5900:5900"  # VNC direct access
```

Then connect with any VNC client to `localhost:5900`

## Architecture

- **Base:** Debian 12 (slim)
- **openMSX:** Compiled on Ubuntu 22.04 with GCC 13
- **hex2bin:** Compiled on Debian 10
- **Multi-stage build:** Optimized final image size

## Resources

- [openMSX Documentation](https://openmsx.org/manual/)
- [SDCC Manual](http://sdcc.sourceforge.net/doc/sdccman.pdf)
- [MSX Assembly Page](http://map.grauw.nl/)
- [MSX Resource Center](https://www.msx.org/)

## Contributing

Contributions welcome! Please open an issue or submit a pull request.
