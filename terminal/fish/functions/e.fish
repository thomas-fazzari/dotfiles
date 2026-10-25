function e --description 'Open a path in nvim'
    set -q argv[1]; or set argv .
    nvim $argv[1]
end
