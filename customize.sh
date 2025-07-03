# video2bootanimation by @rhythmcache

idk() {
	mkdir -p "${MODPATH}/system/bin"
	mv "${MODPATH}/bin" "${MODPATH}/system"
	rm -rf "${MODPATH}/bin"
	set_perm_recursive "${MODPATH}" 0 0 0755 0644
	set_perm_recursive "${MODPATH}/system/bin" 0 0 0755 0755
	ui_print "- Done"
	ui_print " "
}

# Control execution
EXECUTE=1 # Set to 0 to install without creating bootanimation
if [ "${EXECUTE}" -eq 0 ]; then
	ui_print "- Installing Without Creating Bootanimation"
	ui_print "- You Can Later Create Bootanimations by running 'vid2boot' in Terminal"
	idk
	exit 0
fi

zipbin="${MODPATH}/bin/zip"
ffmpeg="${MODPATH}/bin/ffmpeg" # Fixed missing opening bracket
config="/sdcard/cfg"

# Ensure zip and ffmpeg have executable permissions
chmod +x "${zipbin}"
chmod +x "${ffmpeg}"

# Check if zip and ffmpeg are working
if ! "${zipbin}" --help >/dev/null 2>&1; then
	abort "CANNOT LOAD zip, please check the binary"
fi
if ! "${ffmpeg}" -version >/dev/null 2>&1; then
	abort "CANNOT LOAD ffmpeg, please check the binary"
fi

# Define the video file to look for
video=$(find -L /sdcard -maxdepth 1 -type f -iname 'bootvideo.*' | head -n 1)

# Check if the video file exists
if [ ! -f "${video}" ]; then
	abort "CANNOT find any valid bootvideo in /sdcard"
fi

ui_print "- Found video: ${video}"
ui_print " "

# Default resolution and frame rate
default_frame_rate=30
default_resolution=""

# Check for the cfg file
cfg_file=""
if [ -f "${config}" ] && [ -r "${config}" ]; then
	cfg_file="${config}"
elif [ -f "${config}.txt" ] && [ -r "${config}.txt" ]; then
	cfg_file="${config}.txt"
fi

# Process config file if found
if [ -n "${cfg_file}" ] && [ -f "${cfg_file}" ] && [ -r "${cfg_file}" ]; then
	read -r cfg_content <"${cfg_file}"

	# Check if the cfg file has the expected format
	if [[ "${cfg_content}" =~ ^[0-9]+[[:space:]][0-9]+[[:space:]][0-9]+$ ]]; then
		# Extract resolution and fps from cfg file
		res=$(echo "${cfg_content}" | tr -s ' ' '\n')
		width=$(echo "${res}" | head -n 1)
		height=$(echo "${res}" | head -n 2 | tail -n 1)
		frame_rate=$(echo "${res}" | tail -n 1)

		ui_print "- Custom resolution and fps from cfg: ${width}x${height} ${frame_rate}fps"
	else
		ui_print "- Invalid cfg file format or content. Using default device resolution and fps"
		frame_rate="${default_frame_rate}"
	fi
else
	ui_print "- No 'cfg' found or unreadable. Detecting device refresh rate..."

	# Try to get device refresh rate - check if settings command exists first
	if command -v settings >/dev/null 2>&1; then
		refresh_rate=$(settings get system min_refresh_rate 2>/dev/null)
	else
		refresh_rate=""
	fi

	# Check if we got a valid refresh rate (digits with or without decimal)
	if [ -n "${refresh_rate}" ] && echo "${refresh_rate}" | grep -q "^[0-9]*\.*[0-9]*$"; then
		# Extract the integer part (left side of decimal if it exists)
		if echo "${refresh_rate}" | grep -q "\."; then
			# Has decimal point
			refresh_int=$(echo "${refresh_rate}" | cut -d'.' -f1)
		else
			# No decimal point, use as is
			refresh_int="${refresh_rate}"
		fi

		# Validate that refresh_int is a number
		if [ -n "${refresh_int}" ] && [ "${refresh_int}" -eq "${refresh_int}" ] 2>/dev/null; then
			ui_print "- Device refresh rate detected: ${refresh_rate}Hz (${refresh_int})"

			# Apply the fps calculation logic
			if [ "${refresh_int}" -le 60 ]; then
				# Use as is if 60 or less
				frame_rate="${refresh_int}"
				ui_print "- Using fps: ${frame_rate} (refresh rate ≤ 60Hz)"
			else
				# If greater than 60, check if odd or even
				remainder=$((refresh_int % 2))
				if [ "${remainder}" -eq 1 ]; then
					# Odd number: add 1 then divide by 2
					frame_rate=$(((refresh_int + 1) / 2))
					ui_print "- Using fps: ${frame_rate} (odd refresh rate ${refresh_int}+1)/2"
				else
					# Even number: divide by 2
					frame_rate=$((refresh_int / 2))
					ui_print "- Using fps: ${frame_rate} (even refresh rate ${refresh_int}/2)"
				fi
			fi
		else
			ui_print "- Invalid refresh rate value. Using default ${default_frame_rate} fps"
			frame_rate="${default_frame_rate}"
		fi
	else
		ui_print "- Could not detect device refresh rate. Using default ${default_frame_rate} fps"
		frame_rate="${default_frame_rate}"
	fi
fi

# Set resolution for desc.txt
if [ -z "${width}" ] || [ -z "${height}" ]; then
	# Fallback to device resolution if custom resolution is not set
	ui_print "- Determining default device resolution..."
	if cmd window size >/dev/null 2>&1; then
		screen=$(cmd window size | cut -d: -f2 | tr -d " ")
		if [ -z "${screen}" ]; then
			abort "CANNOT get screen size"
		else
			res=${screen//x/ }
			width=$(echo "${res}" | cut -d' ' -f1)
			height=$(echo "${res}" | cut -d' ' -f2)
			ui_print "- RESOLUTION=${width} x ${height}"
			ui_print " "
		fi
	else
		abort "CANNOT GET SCREEN SIZE"
	fi
fi

# Prepare directories in /data/local/tmp
ui_print "- Preparing to extract resources"
TMP_DIR="/data/local/tmp/bootanim"
bootanimation_zip="/data/local/bootanimation.zip"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/bootanimation" "${TMP_DIR}/result"
result="${TMP_DIR}/result/bootanimation.zip"

# Set permissions for the temporary directories
set_perm_recursive "${TMP_DIR}" 0 0 0755 0755

# Analyzing & making Bootanimation
ui_print "- Generating animation from Video....."

# Debug: Check if video file is readable
if [ ! -r "${video}" ]; then
	abort "VIDEO FILE IS NOT READABLE: ${video}"
fi

# Generate frames using ffmpeg
ffmpeg_command="${ffmpeg} -i \"${video}\" -vf \"scale=${width}:${height}\" -f image2 \"${TMP_DIR}/bootanimation/00%05d.jpg\""

# Debug: Print the ffmpeg command before execution
ui_print "- Running FFMPEG"
eval "${ffmpeg_command}" 2>&1 | tee -a /data/local/ffmpeg.log | grep "frame"

# Check for ffmpeg execution error
if [ "${?}" -ne 0 ]; then
	abort "FFMPEG COMMAND FAILED: ${ffmpeg_command}"
fi
sleep 1

# Count frames
count=$(find "${TMP_DIR}/bootanimation" -name "*.jpg" -type f | wc -l)

if [ "${count}" -eq 0 ]; then
	abort "CANNOT generate any frames from the video"
fi

ui_print "- Processed ${count} frames from $(basename "${video}")"
ui_print " "

# Create desc.txt for bootanimation
cd "${TMP_DIR}/result" || abort "CANNOT change to result directory"
if [ -n "${width}" ] && [ -n "${height}" ]; then
	# Create the desc.txt file with resolution and frame rate
	echo "${width} ${height} ${frame_rate}" >"${TMP_DIR}/result/desc.txt" # Save to result directory
else
	abort "CANNOT get resolution and fps"
fi

# Distribute frames into parts if frame count exceeds 400
max_frames_per_part=400
part_index=0
frame_count=0

mkdir -p "${TMP_DIR}/result/part${part_index}"

for frame in "${TMP_DIR}/bootanimation"/*.jpg; do
	mv "${frame}" "${TMP_DIR}/result/part${part_index}/"
	frame_count=$((frame_count + 1))

	# Create a new part directory after every 400 frames
	if [ "${frame_count}" -ge "${max_frames_per_part}" ]; then
		frame_count=0
		part_index=$((part_index + 1))
		mkdir -p "${TMP_DIR}/result/part${part_index}"
	fi
done

# Add lines to desc.txt for each part
for i in $(seq 0 "${part_index}"); do
	echo "p 1 0 part${i}" >>"${TMP_DIR}/result/desc.txt"
done
sleep 1

# Create the bootanimation.zip
ui_print "- Packing bootanimation.zip with zip"
ui_print "- redirected logs to /data/local/zip.log"
cd "${TMP_DIR}/result" || abort "CANNOT change to result directory"
"${zipbin}" -r -0 "${bootanimation_zip}" ./* >/data/local/zip.log

# Check if zip was successful
if [ "${?}" -ne 0 ]; then
	ui_print "Zipping failed, check logs, and report to the developer."
	abort "Zipping failed."
fi
sleep 1

# Check if original bootanimation.zip exists and place the new one systemlessly
ui_print "- Checking where original bootanimation.zip is located"

if [ -f "/system/product/media/bootanimation.zip" ]; then
	ui_print "- Original bootanimation.zip found in /system/product/media"
	dest_dir="${MODPATH}/system/product/media/"
elif [ -f "/system/media/bootanimation.zip" ]; then
	ui_print "- Original bootanimation.zip found in /system/media"
	dest_dir="${MODPATH}/system/media/"
else
	abort "- CANNOT find original bootanimation zip path"
fi

# Create destination directory and copy bootanimation.zip
mkdir -p "${dest_dir}"
cp "${bootanimation_zip}" "${dest_dir}/bootanimation.zip"

# Check if bootanimation-dark.zip exists and replace it as well
if [ -f "/system/product/media/bootanimation-dark.zip" ]; then
	cp "${bootanimation_zip}" "${MODPATH}/system/product/media/bootanimation-dark.zip"
elif [ -f "/system/media/bootanimation-dark.zip" ]; then
	cp "${bootanimation_zip}" "${MODPATH}/system/media/bootanimation-dark.zip"
fi

ui_print "- Bootanimation replaced systemlessly"

# Clean up temporary bootanimation.zip
rm -f "${bootanimation_zip}"

# Exiting
idk
