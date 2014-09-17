#!/bin/bash --
# Myspace music downloader v7.0
# Author of Myspace music downloader <= 5.4: Luka Pusic <luka@pusic.si>
# Author of modifications for a working v6.0 version: Basile Bruneau <basilebruneau@gmail.com>
#
version='7.1'

echo "MySpace music downloader by http://360percents.com & http://ntag.fr"

#Updater - begining
lversionFile=`wget -L "https://raw.github.com/NTag/myspace-dl-cli/master/lastversion" --quiet --user-agent="Mozilla" -O -`
lversion=`echo "$lversionFile" | grep 'version' | sed -e 's/version://' | head -n 1`
lversionChangelog=`echo "$lversionFile" | grep 'changelog' | sed -e 's/changelog://' | head -n 1`
lversionUrl=`echo "$lversionFile" | grep 'url' | sed -e 's/url://' | head -n 1`
if [ "$version" != "$lversion" ]; then
 echo "[-] An update is available (v$lversion>v$version)"
 echo "[-] Fast changelog: $lversionChangelog"
 read -n1 -p "[-] Do you want to download it? (y/n) " wantupdate
 echo ""
 if [ "$wantupdate" = "y" ] || [ "$wantupdate" = "Y" ]; then
  echo "[.] Update"
  nameScript="${0##*/}"
  directory1=`dirname "$0"`
  directory2=`pwd`
  directory="$directory2/$directory1"
  echo "$directory"
  echo "[.] Download..."
  wget -L "$lversionUrl" --quiet -O "$directory/$nameScript"
  echo "[.] Launch of the new version!"
  echo ""
  "$directory/$nameScript" $1
  exit;
 else
  echo "[-] As you want!"
 fi
 echo ""
fi
#Updater - end

if [ -z "$1" ]; then
 echo "";echo "Usage: `basename $0` [USER (eg. eminem)]";echo "";exit
fi

type -P rtmpdump &>/dev/null || {
read -n1 -p "I need a program called rtmpdump, do you wan to install it now? (y/n) "
echo [[ $REPLY = [yY] ]] && sudo apt-get -qq -y install rtmpdump || { echo "You didn't answer yes, or installation failed. Install it manualy. Exiting...";}  >&2; exit 1; }

echo "[+] Requesting $1"
page=`wget -L "http://myspace.com/$1/music/songs" --quiet --user-agent="Mozilla" -O -`

songs=`echo "$page" | grep '<button class="playBtn play_25 song" data-type="song"'`

songcount=$((`echo "$songs" | wc -l`))
if [ $((`echo "$songs" | wc -c`)) -lt "2" ]; then
 echo "[+] ERROR: no songs found at this url."
 echo "[-] Please submit bugs to: http://360percents.com/posts/linux-myspace-music-downloader/ and http://projets.ntag.fr/dlmyspace/";exit
fi
echo "[+] Found $songcount songs."

swf=`echo "$page" | grep '"playerSwf":"' | sed -e 's/.*"playerSwf":"//' -e 's/".*//' | head -n 1`

for i in `seq 1 $songcount`
do
 song=`echo "$songs" | sed -n "$i"p`
 artistname=`echo "$song" | sed -e 's/.*data-artist-name="//' -e 's/".*//' -e 's/\\//-/g' -e 's/[^A-Za-z0-9_]/_/g' -e 's/_\+/_/g' -e 's/^_//' -e 's/_$//' | head -n 1`
 albumname=`echo "$song" | sed -e 's/.*data-album-title="//' -e 's/".*//' -e 's/\\//-/g' -e 's/[^A-Za-z0-9_]/_/g' -e 's/_\+/_/g' -e 's/^_//' -e 's/_$//' | head -n 1`
 title=`echo "$song" | sed -e 's/.*data-title="//' -e 's/".*//' -e 's/\\//-/g' -e 's/[^A-Za-z0-9_]/_/g' -e 's/_\+/_/g' -e 's/^_//' -e 's/_$//' | head -n 1`
 rtmpb=`echo "$song" | sed -e 's/.*data-stream-url="//' -e 's/".*//' | head -n 1`
 file=`echo "$rtmpb" | sed 's/.*;//' | head -n 1`
 rtmp=`echo "$rtmpb" | sed 's/;.*//' | head -n 1`
 
 echo "[+]  Downloading $title..."
 rtmpdump -r "$rtmp" -a "" -f "LNX 11,2,202,235" -o "${albumname:-$artistname}-${title}.flv" -q -W "$swf" -p "http://www.myspace.com" -y "$file"
 
 if which ffmpeg >/dev/null; then
  echo "[+]  Converting $title to mp3..."
  (ffmpeg -y -i "${albumname:-$artistname}-${title}.flv" -metadata TITLE="$title" -metadata ARTIST="$artistname" -metadata ALBUM="$albumname" -acodec libmp3lame -ab 192000 -ar 44100 -f mp3 "${albumname:-$artistname}-${title}.mp3" > /dev/null 2>&1 && rm "${albumname:-$artistname}-${title}.flv") &
 fi
done
