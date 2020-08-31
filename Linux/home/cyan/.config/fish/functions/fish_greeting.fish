function fish_greeting
  set host (hostname | cut -f1 -d".")
  if test "$host" = "boole"
    set wthr (~/bin/weather)
    clear
    echo "╔══════════════════════════════╗"
    echo "║  Welcome to boole, $USER!   ║"
    echo "║   It's currently $wthr.   ║"
    echo "╚══════════════════════════════╝"
    echo ""
  else
    fortune -n 50 -s
  #pfetch
end
