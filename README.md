fork of pimatic-efergy-e2
=======================

Pimatic plugin to gather power consumption from Efergy E2 (and other clone devices including Chacon EcoWatt)
using a RTL-SDR compatible dongle.
This plugin use the rtl_433 executable (https://github.com/merbanan/rtl_433)

Dependencies
------------

Compiling rtl_433 requires [rtl-sdr](http://sdr.osmocom.org/trac/wiki/rtl-sdr) to be installed.

Depending on your system, you may also need to install the following libraries:

    sudo apt-get install libtool libusb-1.0.0-dev librtlsdr-dev rtl-sdr

See [rtl_433 readme](https://github.com/merbanan/rtl_433/blob/master/README.md) for more details.

Thanks
------

Thanks to merbanan and the rtl_433 community for their support and to maintain that very nice tool.
