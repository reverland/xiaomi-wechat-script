#!/usr/bin/env bash
set -ex

origin_file=$(ls "$1"/*.bak)
desc_file=$(ls "$1/descript.xml")
if ! [ -e "$origin_file" ]; then
   exit 1
fi

temp_dir=$(mktemp -d -p .)
android_bak=$temp_dir/backup.ab
android_tar_filename=backup.tar
android_tar=$temp_dir/$android_tar_filename
uin_xml=$temp_dir/uin_file_path.xml
imei_xml=$temp_dir/imei_file_path.xml
dec_db=$temp_dir/MicroMsg.db
miui_header=$temp_dir/header
output_date=$(($(date +%s%N)/1000000))
dest_dir=dest
mkdir -p "$dest_dir"
output_dir=$dest_dir/$(date +"%Y%m%d_%H%M%S")
mkdir -p "$output_dir"
output_bak_filename=微信改.bak
output_bak=$output_dir/$output_bak_filename
output_desc_xml=$output_dir/descript.xml

# skip MIUI header to get android backup file
dd skip=41 iflag=skip_bytes if="$origin_file" of="$android_bak"
# unpack android backup files to tar
java -jar abe-all.jar unpack "$android_bak" "$android_tar"
# extract EnMicroMsg.db from tar
db_path=$(tar -tf "$android_tar" --wildcards "*EnMicroMsg.db")
enc_db=$temp_dir/$db_path
mkdir -p $(dirname "$enc_db")
tar -xOvf "$android_tar" "$db_path" > "$enc_db"
uin_file_path=$(tar -tf "$android_tar" --wildcards "*auth_info_key_prefs.xml")
tar -xOvf "$android_tar" "$uin_file_path" > "$uin_xml"
imei_file_path=$(tar -tf "$android_tar" --wildcards "*sp/DENGTA_META.xml")
tar -xOvf "$android_tar" "$imei_file_path" > "$imei_xml"
# decrypt encrypted micro msg database
python decrypt.py "$uin_xml" "$imei_xml" "$enc_db" "$dec_db"

echo "Please edit dec_db"
sqlitebrowser "$dec_db"
echo "encrypt back"
# encrypt modified micro msg database back
rm -f "$enc_db"
python encrypt.py "$uin_xml" "$imei_xml" "$dec_db" "$enc_db"
# update EnMicroMsg to tar
(
    cd "$temp_dir"
    tar -uvf "$android_tar_filename" "$db_path"
)
# pack tar to android backup file
java -jar abe-all.jar pack "$android_tar" "$android_bak"
head -c 41 "$origin_file" > "$miui_header"
cat "$miui_header" "$android_bak" > "$output_bak"
output_bak_size=$(stat --print="%s" "$output_bak")
python update_desc.py "$desc_file" "$output_date" "$output_bak_size" "$output_bak_filename" "$output_desc_xml"
