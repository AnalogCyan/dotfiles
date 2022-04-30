function ytmdl-sp --description 'ytmdl <spotify-id> <youtube-url>'
  set id $argv[1]
  set url $argv[2]
  if string match -e "spotify:track:" "$id"
    set id (string replace "spotify:track:" "" "$id")
  end
  if string match -e "youtu.be" "$url"
    set url (string replace "youtu.be/" "youtube.com/watch?v=" "$url")
  end
  ytmdl --nolocal --spotify-id "$id" --url "$url"
end