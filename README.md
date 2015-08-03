# Xion345 FPGA Projects 

This repository contains small — and hopefully fun! — FPGA projects I have been
working on during my free time — nothing big and professional.

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
