# Defined in - @ line 0
function generate-password --description ''
	bash -c "< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c\${1:-32};echo;"  $argv;
end
