function yt-dlp-bv --description 'alias for yt-dlp w/ best video settings'
  yt-dlp --downloader "m3u8:ffmpeg" --write-description --write-info-json --write-playlist-metafiles --write-thumbnail --write-link --write-subs --sub-format best --sub-langs all --compat-options no-live-chat --embed-subs --embed-thumbnail --embed-metadata --embed-chapters -f "bv*+ba/bv+ba/b" --video-multistreams --audio-multistreams --merge-output-format mp4 --output "./%(title)s [%(height)sp %(fps)s]/%(title)s [%(height)sp %(fps)s].%(ext)s" "$argv";
end
