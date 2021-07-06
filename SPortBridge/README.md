OlliW Telemetry for OpenTx/EdgeTx with MAVLink: SPort Bridge
===========

The SPort Bridge translates between the bi-directional one-wire communication signal on the SPort pin and the normal bi-directional two-wire (Tx, Rx) UART signals.

Hardware-wise this requires two functional units, a unit which is doing the splicing from one to two and also inverts the signals, and a microprocessor which decodes/encodes the signal on the one-wire line. 

Comment: The principle is not new at all and widley used. It is e.g. also used in the MPM (multi protocol module) or Siyi FM30 (which just copied it from MNM).

Comment: Microcontroller exist which do provide the slice&invert function internally, which would allow a significantly reduced scheme. The STM32F103, which I use here, does not have that, hence the extra "chicken fat", but I use it since it is also used in the Siyi FM30 transmitter module, which is an excellent commercially available and reasonably priced hardware platform for our purposes. So, the PCB here is actually kind of a development platform for that.

The PCB can be populated such that it exactly reproduces the splicing/inverting unit as used in the MPM and Siyi FM30 (which is normally high level), but it also can be populated such that it is more appropriate for a normally low signal like the one on the SPort (I use that scheme).

The microcontroller needs to be loaded with code, an example C code is provided (you need to spice it up with what it needs to build it).

Comment: I would have loved to provide an Arduino sketch, since this would be really the easiest for most, but I could not figure out how to call low level CMSIS functions in this framework. MAybe some can provide an example or help me out with this.

