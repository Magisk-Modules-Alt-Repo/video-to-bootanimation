## video-to-bootanimation
A Magisk/KernelSU Module that sets an MP4 video as the android device's boot animation.


[![Telegram](https://img.shields.io/badge/Telegram-blue?style=flat-square&logo=telegram)](https://rhythmcache.t.me)
![Downloads](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/video-to-bootanimation/total.svg)

## How to Use
- Rename your MP4 video to `bootvideo.mp4` and place it in your internal storage (`/storage/emulated/0/`).  
You can create a file named `cfg` in internal storage and can configure the resolution and FPS of your boot animation by editing that file.

- For example, entering `720 1280 25` in cfg file will set the boot animation resolution to 720x1280 and the FPS to 25.  
If you delete the `cfg` file or leave it empty, the module will automatically detect your screen resolution and configure itself accordingly while running. The default FPS is fixed and will be 30 , but as i said you can configure it by creating a cfg file.

---

- If you just want to install the module and don't want to create a bootanimation during the installation of module, unzip the module and change the [value of this line of customize.sh](https://github.com/Magisk-Modules-Alt-Repo/video-to-bootanimation/blob/main/customize.sh#L15) to `0`, this will skip the whole bootanimation creation process during installation of the module.
- You can later create flashable boot animations using the `terminal`


### Terminal Commands

- After installing the module, run these commands with `root` permissions:

- `vid2boot` in Termux or any terminal emulator to generate a flashable bootanimation magisk module from videos.

- `boot2vid` to convert a supported bootanimation.zip into a video.


## Compatibility 
- Should work on every ROM which uses a `/system/media/bootanimation.zip` or  `/system/product/media/bootanimation.zip` format for playing bootanimation. 

## Bugs
- ~Might not work on MIUI/HyperOS/OxygenOS (never tested)
- Samsung uses a .QMG format for boot animations, meaning this animation also won't work on your Samsung device.
- Might not work on devices of non-arm64 architecture , to fix you have to put `ffmpeg` and `zip` binary of respective architecture to the module"s bin folder. (you have to find the binary by yourself)
- Module doesn’t terminate : KernelSU may show the status as "flashing" even though the flashing process is complete. As soon as you see `done` in the output, press the back button.

<!--
- found any bugs?
  [tell here](https://t.me/ximistuffschat)
--->

# Alternative Approach
- You can use [this script](https://github.com/rhythmcache/Video-to-BootAnimation-Creator-Script/tree/main) to convert videos into a Bootanimation magisk module , which can be flashed directly in magisk. you don't need to create any cfg etc

## Download

[Download Latest Release](https://github.com/rhythmcache/video-to-bootanimation/releases/download/V3/video-to-bootanimation-main.zip)

---

- Prebuilt Binaries Source
- [ffmpeg](https://github.com/Khang-NT/ffmpeg-binary-android)
- [bash](https://github.com/Magisk-Modules-Alt-Repo/mkshrc/tree/master/common/bash)
- [zip](https://packages.termux.dev/apt/termux-main/pool/main/z/zip/)

## License

    This Program Is Free Software. You can redistribute
    it
    and/or modify it under the terms of the GNU General
    Public
    License as published by the Free Software Foundation, either version 3
    of the License , or (at your option) 
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
