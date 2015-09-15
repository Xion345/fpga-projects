# Xion345 FPGA Projects 

This repository contains small — and hopefully fun! — FPGA projects I have been
working on during my free time.

Components are written in VHDL and were synthesized for a Spartan 6 FPGA. I use
a [Digilent Nexys3](http://www.digilentinc.com/nexys3/) board for prototyping.
Development was done using Xilinx ISE 14.7.

This repository is organized as follows:
      
- **library/**  Contains VHDL components (\*.vhd), such as block RAMs, counters or
I/O controllers used by different projects.
- **code/** Contains Python and C programs used to format data (pictures etc.)
  for the FPGA, or to interact with the FPGA from a host computer
- **projects/** Contains projects folders. Each project folder contains a Xilinx
  ISE project file (\*.xise)

## Licence ##

All files in this repository are distributed under the MIT licence (see LICENCE).

## List of projects ##

- **vga-palette:** Simple VGA test circuit displaying a 256 color palette on a 
screen. Red, green and blue components can be disabled. Mostly useful to check if
hsync/vsync signals are properly generated and if each component is properly wired.

- **vga-tiled-framebufer:** VGA framebuffer displaying a picture transferred over
UART on an external screen. The picture must be sliced into 8x16 pixels tiles
before being sent (256 tiles at most). Includes python scripts to slice pictures
into tiles and transfer them over UART from a computer (requires PIL and pyserial)


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Xion345/fpga-projects/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

