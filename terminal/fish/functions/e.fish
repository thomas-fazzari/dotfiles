function e --description 'Open paths in nvim'
    set -q argv[1]; or set argv .
    nvim $argv
end
