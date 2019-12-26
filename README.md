pimatic-rtl433
=======================

Pimatic plugin to display datas from temperature and humidity sensors using a RTL-SDR compatible dongle.
This plugin use the rtl_433 executable (https://github.com/merbanan/rtl_433)

Installation
------------
Install dependencies (See [rtl_433 readme](https://github.com/merbanan/rtl_433/blob/master/README.md) for more details.):

    sudo apt-get install cmake libtool libusb-1.0.0-dev librtlsdr-dev rtl-sdr

Change to your pimatic node_modules folder:

    cd /home/pi/pimatic-app/node_modules

Clone the repository:

    git clone https://github.com/Ax-LED/pimatic-rtl433.git

Change into plugin folder:

    cd pimatic-rtl433

Install Plugin:

    npm install

Thanks
------

Thanks to merbanan and the rtl_433 community for their support and to maintain that very nice tool.
Thanks to David Pirlot, his plugin [pimatic-efergy-e2](https://github.com/DavidBel86/pimatic-efergy-e2/) was base of this plugin.
