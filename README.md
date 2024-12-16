## video-to-bootanimation
A Magisk/KernelSU script that sets an MP4 video as the android device's boot animation.

## How to Use
Rename your MP4 video to `bootvideo.mp4` and place it in your internal storage (`/storage/emulated/0/`).  
You can create a file named `cfg` in internal storage and can configure the resolution and FPS of your boot animation by editing that file.
For example, entering `720 1280 25` in cfg file will set the boot animation resolution to 720x1280 and the FPS to 25.  
If you delete the `cfg` file or leave it empty, the module will automatically detect your screen resolution and configure itself accordingly while running. The default FPS is fixed and will be 30 , but as i said you can configure it by creating a cfg file.

## Bugs
- ~~Might not work on MIUI/HyperOS. (never tested)~~
- Samsung uses a .QMG format for boot animations, meaning this animation also won't work on your Samsung device.
- Might not work on devices of non-arm64 architecture , to fix you have to put `ffmpeg` and `zip` binary of respective architecture to the module"s bin folder. (you have to find the binary by yourself)
- Script doesn’t terminate : KernelSU may show the status as "flashing" even though the flashing process is complete. As soon as you see `done` in the output, press the back button.



- found any bugs?
  [tell here](https://t.me/ximistuffschat)

# Alternative Approach
- You can use [this script](https://github.com/rhythmcache/Video-to-BootAnimation-Creator-Script/tree/main) to convert videos into a Bootanimation magisk module , which can be flashed directly in magisk. you don't need to create any cfg etc

## Download

[Download Latest Release](https://github.com/rhythmcache/video-to-bootanimation/releases/download/V3/video-to-bootanimation-main.zip)

---
[![Telegram](https://img.shields.io/badge/Telegram-Join%20Chat-blue?style=flat-square&logo=telegram)](https://t.me/ximistuffschat)
