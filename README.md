# archeage-proton-tzfix

Fixes this error when starting ArcheAge Chronicles on Linux through Proton:

> The procedure entry point SystemTimeToTzSpecificLocalTimeEx could not be located in the dynamic link library KERNEL32.dll.

Wine, and every Proton built on it, has `SystemTimeToTzSpecificLocalTimeEx` and `TzSpecificLocalTimeToSystemTimeEx` only as stubs in kernelbase and does not export them from kernel32. ArcheAge Chronicles imports them from kernel32, so it fails at launch.

This repository adds both functions and ships rebuilt `kernel32.dll` and `kernelbase.dll` for proton-cachyos 11.0-20261015. The installer copies your existing proton-cachyos into a new Steam compatibility tool, `proton-cachyos-tzfix`, and replaces only those DLLs.

Upstream report: [ValveSoftware/Proton#10337](https://github.com/ValveSoftware/Proton/issues/10337)

## Requirements

- proton-cachyos **11.0-20261015** (`cachyos-11.0-20261015-slr`) installed. On Arch and CachyOS this is the `proton-cachyos-slr` package. The DLLs are built for this exact version. Do not copy them into other Proton builds.

## Install

```sh
git clone https://github.com/hiraethi/archeage-proton-tzfix
cd archeage-proton-tzfix
./install.sh
```

Then restart Steam and open ArcheAge Chronicles → Properties → Compatibility. Enable "Force the use of a specific Steam Play compatibility tool" and select **proton-cachyos-tzfix (time-zone fix)**.

The installer checks the DLLs against `SHA256SUMS` before copying anything.

## Uninstall

Switch the game back to its previous compatibility tool, then delete `~/.local/share/Steam/compatibilitytools.d/proton-cachyos-tzfix`.

## Risks

- ArcheAge Chronicles uses the XIGNCODE3 anti-cheat. The game and XIGNCODE3 start with this fix, but modified system DLLs can be flagged by anti-cheat software. Use at your own risk.
- This is a stopgap until an official Proton release includes the functions.

## Building from source

`tzspecific-ex.patch` applies to Wine master and to [CachyOS/wine-cachyos](https://github.com/CachyOS/wine-cachyos) at `cd14106`, the Wine source of proton-cachyos 11.0-20261015. Apply it, configure with `--enable-archs=i386,x86_64`, and build:

```sh
make dlls/kernelbase/x86_64-windows/kernelbase.dll dlls/kernel32/x86_64-windows/kernel32.dll \
     dlls/kernelbase/i386-windows/kernelbase.dll dlls/kernel32/i386-windows/kernel32.dll
```

The patch was written with the help of an AI assistant.

## License

The DLLs are built from Wine and are licensed under the GNU LGPL 2.1 or later; see `LICENSE`. Corresponding source: Wine at the commit above plus `tzspecific-ex.patch`.
