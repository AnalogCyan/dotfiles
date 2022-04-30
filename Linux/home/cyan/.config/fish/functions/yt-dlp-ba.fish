function yt-dlp-bv --description 'alias for yt-dlp w/ best audio settings'
  yt-dlp --downloader "m3u8:ffmpeg" --write-description --write-info-json --write-playlist-metafiles --write-thumbnail --write-link --write-subs --sub-format best --sub-langs all --compat-options no-live-chat --embed-subs --embed-thumbnail --embed-metadata --embed-chapters -f "ba" --audio-format mp3 --remux-video mp3 --audio-multistreams --output "./%(title)s [%(acodec)s]/%(title)s [%(acodec)s].%(ext)s" "$argv";
end
