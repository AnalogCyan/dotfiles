function fish_greeting
  clear
  set wthr (~/bin/weather)
  pfetch
  echo "It's currently $wthr."
  fortune -n 50 -s
end