# Godot - LGPIO
GDScript client for [lgpio](https://abyz.me.uk/lg/index.html) - Makes it easier to interact with GPIO on your Raspberry Pi or other SBC.

[!["Buy Me A Coffee"](https://buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/valbisson)

# Setup
1. install `rgpiod` on the computer you want to control (eg Raspberri Pi).
2. run it: `sudo rgpiod`
3. on your host (where the Godot-lgpio will be running, possibly the same host,
depending on you situation) [install](#requirements) `rgs`
4. you're ready to use the app!

# Requirements
- on Raspberri Pi: `sudo apt-get install rgpio-tools`
- others: download/compile `rgs` using [lgpio's install info](https://abyz.me.uk/lg/download.html)

# Introduction
Here's a quick rundown of the main classes:
- `lgpio`: `class_name`'d to make it globally available, it can be considered a
namespace for the project, so that no other gd script needs to be imported in most cases.
- `lgpio.Chip`: refers to a gpiochip under [the kernel's GPIO driver interface](https://docs.kernel.org/driver-api/gpio/driver.html).
It basically means a board (eg 1 Pi).
- `lgpio.GPIO`: this is a single pin on a board. GPIOs on a PI are numbererd
[as such](https://pinout.xyz/):
<p align="center">
  <img src="misc/rpi_pinout.png" alt="RPi pinout"/>
</p>

# Usage
Check out scenes in the `samples` directory. Each scene can be played independently (`F6`).

Note:
- by default, `Godot-lgpio` connects to `localhost`, ie it access GPIOs of the board
it runs on.
- set `LG_ENVADDR` & `LG_ENVPORT` to work remotely and access GPIOS of the board
at those address & port.


# Facilities
## Devices
LGPIO implements a few abstractions similar to [gpiozero](https://gpiozero.readthedocs.io/en/latest/api_output.html#base-classes)
(this is very much a work-in-progress).

Legend:
- lighter classes are abstract
- darker ones are concrete / instanciable
- classes marked with a ✔ have been implemented
- classes marked with a ✖ are not written yet (I may lack the hardware to test them,
contributions are welcome!)


```mermaid
flowchart RL
	Device[Device ✖]
	class Device abstract
	GPIODevice[GPIODevice ✔] --> Device
	class GPIODevice abstract
	RGBLED[RGBLED ✖] --> Device
	CompositeDevice[CompositeDevice ✔] --> Device
	class CompositeDevice abstract

	OutputDevice[OutputDevice ✔] --> GPIODevice

	DigitalOutputDevice[DigitalOutputDevice ✔] --> OutputDevice
	PWMOutputDevice[PWMOutputDevice ✔] --> OutputDevice

	Buzzer[Buzzer ✖] --> DigitalOutputDevice
	LED[LED ✖] --> DigitalOutputDevice

	PWMLED[PWMLED ✖] --> PWMOutputDevice

	Servo[Servo ✖] --> CompositeDevice
	Motor[Motor ✖] --> CompositeDevice
	PhaseEnableMotor[PhaseEnableMotor ✔] --> CompositeDevice
	TonalBuzzer[TonalBuzzer ✖] --> CompositeDevice

	AngularServo[AngularServo ✖] --> Servo


	classDef abstract fill:#d4ffa6,stroke:#000
	classDef default fill:#86bc4c,stroke:#000
```

## Logging
`Godot-LGPIO` logs under 4 levels:

- `DEBUG`: Logs most events and gives a verbose overview of what's happening in the lib.
- `INFO`: Default level.
- `WARNING`: for local errors detected within this lib.
- `ERROR`: when the underlying stack (rgs/lgpio) returns errors.

# WIP Status
Not all of `lgpio` API is implemented. This is a work in progress where PRs are
welcome. In addition to the high-level classes described above, here's a table to
track which which parts of [rgs API](https://abyz.me.uk/lg/rgs.html) are supported:

| Command | Supported |
| :-------| :-------: |
| FILES   | --------- |
| FO      | ✖         |
| FC      | ✖         |
| FR      | ✖         |
| FW      | ✖         |
| FS      | ✖         |
| FL      | ✖         |
| GPIO    | --------- |
| GO      | ✔         |
| GC      | ✔         |
| GIC     | ✔         |
| GIL     | ✔         |
| GMODE   | ✔         |
| GSI     | ✔         |
| GSIX    | ✔         |
| GSO     | ✔         |
| GSOX    | ✔         |
| GSA     | ✖         |
| GSAX    | ✖         |
| GSF     | ✔        |
| GSGI    | ✔        |
| GSGIX   | ✔        |
| GSGO    | ✔        |
| GSGOX   | ✔        |
| GSGF    | ✔        |
| GR      | ✔        |
| GW      | ✔        |
| GGR     | ✖         |
| GGW     | ✖         |
| GGWX    | ✖         |
| GP      | ✔        |
| GPX     | ✔        |
| P       | ✖         |
| PX      | ✖         |
| S       | ✖         |
| SX      | ✖         |
| GWAVE   | ✖         |
| GBUSY   | ✖         |
| GROOM   | ✖         |
| GDEB    | ✖         |
| GWDOG   | ✖         |
| I2C     | --------- |
| I2CO    | ✖         |
| I2CC    | ✖         |
| I2CWQ   | ✖         |
| I2CRS   | ✖         |
| I2CWS   | ✖         |
| I2CRB   | ✖         |
| I2CWB   | ✖         |
| I2CRW   | ✖         |
| I2CWW   | ✖         |
| I2CRK   | ✖         |
| I2CWK   | ✖         |
| I2CWI   | ✖         |
| I2CRI   | ✖         |
| I2CRD   | ✖         |
| I2CWD   | ✖         |
| I2CPC   | ✖         |
| I2CPK   | ✖         |
| I2CZ    | ✖         |
| NOTIFICATIONS | --- |
| NO      | ✖         |
| NC      | ✖         |
| NP      | ✖         |
| NR      | ✖         |
| SCRIPTS | --------- |
| PROC    | ✖         |
| PROCR   | ✖         |
| PROCU   | ✖         |
| PROCP   | ✖         |
| PROCS   | ✖         |
| PROCD   | ✖         |
| PARSE   | ✖         |
| SERIAL  | --------- |
| SERO    | ✖         |
| SERC    | ✖         |
| SERRB   | ✖         |
| SERWB   | ✖         |
| SERR    | ✖         |
| SERW    | ✖         |
| SERDA   | ✖         |
| SHELL   | --------- |
| SHELL   | ✖         |
| SPI     | --------- |
| SPIO    | ✖         |
| SPIC    | ✖         |
| SPIR    | ✖         |
| SPIW    | ✖         |
| SPIX    | ✖         |
| UTILITIES | ------- |
| LGV     | ✖         |
| SBC     | ✖         |
| CGI     | ✖         |
| CSI     | ✖         |
| T/TICK  | ✖         |
| MICS    | ✖         |
| MILS    | ✖         |
| U/USER  | ✖         |
| C/SHARE | ✔ (Chip._share_id) |
| LCFG    | ✖         |
| PCD     | ✖         |
| PWD     | ✖         |
