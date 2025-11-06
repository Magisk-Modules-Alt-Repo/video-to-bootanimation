# video-to-bootanimation
A **Magisk/KernelSU Module** that lets you set an MP4 video as your Android device's **boot animation** — no PC required.

[![Telegram](https://img.shields.io/badge/Telegram-blue?style=flat-square&logo=telegram)](https://rhythmcache.t.me)
![Downloads](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/video-to-bootanimation/total.svg)

---

## 📖 How to Use

1. **Place your video:**
   - Rename your MP4 video to `bootvideo.mp4`.
   - Move it to your internal storage:  
     `/storage/emulated/0/` (or `/sdcard/`).

2. **(Optional) Configure settings:**
   - Create a file named `cfg.txt` in `/sdcard/` with any of these keys:  

     ```ini
     # video2boot configuration file
     # Lines starting with # are ignored. Empty values = auto-detect.

     # Optional custom video path
     video=/sdcard/bootvideo.mp4

     # Optional output resolution
     width=1080
     height=2400

     # Optional frame rate
     fps=60

     # Include audio from video (on/off)
     audio=on

     # Target install location
     # (auto | system/media | system/product/media)
     output=auto
     ```

   - Leave values blank or omit lines to let the binary **auto-detect resolution, frame rate, and location**.

3. **Flash the module in Magisk or KernelSU.**
   - It will automatically convert the video to a bootanimation ZIP during installation.
   - If `audio=on`, the resulting animation will include sound.

---

##  Terminal Commands

After installing, you can run the following with **root privileges**:

| Command | Description |
|----------|-------------|
| `vid2boot` | Converts a video into a flashable bootanimation Magisk module. |
| `boot2vid` | Converts a bootanimation.zip back into a video. |

Both commands support most standard MP4 files and handle scaling, FPS, and audio automatically.

---

##  Compatibility

 Works on:
- Any ROM that uses `bootanimation.zip` under `/system/media/` or `/system/product/media/`.

⚠️ May not work on:
- **Samsung** devices (use `.QMG` format).
- **MIUI/HyperOS/OxygenOS** (not tested yet).
- **Some Custom ROMs**

💡 KernelSU may sometimes show “flashing” indefinitely even after completion — once you see “Done” in the log, simply go back.

---

##  Download

🔽 [Download Latest Release](https://github.com/rhythmcache/video-to-bootanimation/releases/download/V3/video-to-bootanimation-main.zip)

## License

```
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```

---

Maintained by **@rhythmcache**
