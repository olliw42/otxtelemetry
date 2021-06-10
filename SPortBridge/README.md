OlliW Telemetry for OpenTx/EdgeTx with MAVLink: SPort Bridge
===========

The SPort Bridge translates between the bi-directional one-wire communication signal on the SPort pin and the normal bi-directional two-wire (Tx, Rx) UART signals.

Hardware-wise this requires two functional units, a unit which which is doing the splicing from one to two and also inverts the signals, and a microprocessor which decodes/encodes the signals on the two ends. 

Comment: The principle is not new at all and widley used. It is e.g. also used in the MPM (multi protocol module). 

The PCB can be populated such that it exactly reproduces the splicing/inverting unit as used in the MPM (which is normal level high), but it also can be populated such that it is more approporuiet for a normally low signal like the one on the SPort (I use that scheme).

The microcontroller needs to be loaded with code, an example C code is provided (you need to spice it up with what it needs to build it).

Comment: I would have loved to provide an Arduino sketch, since this would be really the easiest for most, but I could not figure out how to call low level CMSIS functions in this framework. MAybe some can provide an example or help me out with this.

