# video2bootanimation by @rhythmcache
MOD_BIN="${MODPATH}/system/bin"
mkdir -p "${MOD_BIN}"

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- Detected architecture: ${ARCH}"

if [ ! -f "${MODPATH}/bins.tar.xz" ]; then
	BASE_URL="https://raw.githubusercontent.com/Magisk-Modules-Alt-Repo/video-to-bootanimation/main/bins"
	for bin in vid2boot ffmpeg ffprobe; do
		ui_print "- Downloading ${bin}-${ARCH}..."
		wget -q -O "${MOD_BIN}/${bin}" "${BASE_URL}/${bin}-${ARCH}" || abort "FAILED to download ${bin}"
		chmod 0755 "${MOD_BIN}/${bin}"
	done
else
	ui_print "- Found local bins.tar.xz, extracting..."
	cd "${MODPATH}" || abort "Cannot cd to ${MODPATH}"
	tar -xf bins.tar.xz || abort "Failed to extract bins"
	cp "bins/ffmpeg-${ARCH}"  "${MOD_BIN}/ffmpeg"  || abort "Missing ffmpeg-${ARCH}"
	cp "bins/vid2boot-${ARCH}" "${MOD_BIN}/vid2boot" || abort "Missing vid2boot-${ARCH}"
	cp "bins/ffprobe-${ARCH}" "${MOD_BIN}/ffprobe" || abort "Missing ffprobe-${ARCH}"
	chmod 0755 "${MOD_BIN}/ffmpeg" "${MOD_BIN}/vid2boot" "${MOD_BIN}/ffprobe"
	rm -rf "${MODPATH}/bins" "${MODPATH}/bins.tar.xz"
fi

export FFMPEG_PATH="${MOD_BIN}/ffmpeg"
export FFPROBE_PATH="${MOD_BIN}/ffprobe"
ui_print " "

video=""
width=""
height=""
fps=""
audio=""
output="auto"

CFG="/sdcard/cfg.txt"
if [ -f "$CFG" ]; then
	ui_print "- Reading configuration from $CFG"
	while IFS='=' read -r key val; do
		[ -z "$key" ] && continue
		case "$key" in
			video)  video="$val" ;;
			width)  width="$val" ;;
			height) height="$val" ;;
			fps)    fps="$val" ;;
			audio)  audio="$val" ;;
			output) output="$val" ;;
		esac
	done < <(grep -v '^[[:space:]]*#' "$CFG" | grep '=')
fi

if [ -z "$video" ]; then
	video=$(find -L /sdcard /storage/emulated/0 -maxdepth 1 -type f -iname 'bootvideo.*' | head -n1)
fi
[ -f "$video" ] || abort "No valid bootvideo found."
ui_print "- Using video: $video"

if [ -z "$width" ] || [ -z "$height" ]; then
	res=$(cmd window size 2>/dev/null | awk -F: '{print $2}' | tr -d ' ')
	width=${res%x*}
	height=${res#*x}
	if [ -n "$width" ] && [ -n "$height" ]; then
		ui_print "- Detected resolution: ${width}x${height}"
	else
		ui_print "- Resolution auto-detection failed, letting vid2boot auto decide..."
	fi
fi

if [ -z "$fps" ]; then
	fps=$(settings get system peak_refresh_rate 2>/dev/null)
	[ -z "$fps" ] && fps=$(settings get system min_refresh_rate 2>/dev/null)
	if [ -n "$fps" ]; then
		ui_print "- Detected refresh rate: ${fps}Hz"
	else
		ui_print "- Refresh rate auto-detection failed, letting vid2boot auto decide....."
	fi
fi

if [ "$output" = "system/product/media" ]; then
	MOD_MEDIA="${MODPATH}/system/product/media"
elif [ "$output" = "system/media" ]; then
	MOD_MEDIA="${MODPATH}/system/media"
else
	if [ -f "/system/product/media/bootanimation.zip" ]; then
		MOD_MEDIA="${MODPATH}/system/product/media"
		ui_print "- Detected existing bootanimation: /system/product/media"
	elif [ -f "/system/media/bootanimation.zip" ]; then
		MOD_MEDIA="${MODPATH}/system/media"
		ui_print "- Detected existing bootanimation: /system/media"
	else
		MOD_MEDIA="${MODPATH}/system/media"
		ui_print "- No existing bootanimation found, defaulting to /system/media"
	fi
fi
mkdir -p "$MOD_MEDIA"

vid2boot_cmd="${MOD_BIN}/vid2boot -i \"${video}\" -o \"${MOD_MEDIA}/bootanimation.zip\""
[ -n "$width" ] && [ -n "$height" ] && vid2boot_cmd="${vid2boot_cmd} -W ${width} -H ${height}"
[ -n "$fps" ] && vid2boot_cmd="${vid2boot_cmd} -f ${fps}"
[ "$audio" = "on" ] && vid2boot_cmd="${vid2boot_cmd} --with-audio"

ui_print "- Generating bootanimation..."
eval "${vid2boot_cmd}" 2>&1 | while IFS= read -r line; do ui_print "  ${line}"; done
[ -f "${MOD_MEDIA}/bootanimation.zip" ] || abort "Bootanimation generation failed."
ui_print "- Bootanimation.zip created successfully"

for path in /system/product/media /system/media; do
	if [ -f "${path}/bootanimation-dark.zip" ]; then
		cp "${MOD_MEDIA}/bootanimation.zip" "${MOD_MEDIA}/bootanimation-dark.zip"
		ui_print "- Also replaced bootanimation-dark.zip"
		break
	fi
done

ui_print "- Bootanimation replaced systemlessly"
ui_print "- Installation complete"
