function fuck
    if test "$argv"
        command sudo $argv
    else
        eval command sudo $history[1]
    end
end