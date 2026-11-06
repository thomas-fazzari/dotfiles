function ws --description 'Set up my default Rex session in the current one'
    set -q REX_SESSION REX_BLOCK; or begin
        echo "ws: not in a Rex terminal" >&2
        return 1
    end

    # Open on the review of uncommitted changes when there are some
    set -l nvim_cmd nvim
    if test -n "$(git status --porcelain 2>/dev/null)"
        set nvim_cmd nvim +CodeDiff
    end

    set -l repo (git rev-parse --show-toplevel 2>/dev/null; or echo $PWD)
    rex session rename $REX_SESSION (path basename $repo) >/dev/null

    set -l tab (rex block inspect $REX_BLOCK --json | jq -r .block.window_id)
    or return 1
    rex window rename -s $REX_SESSION $tab pi >/dev/null
    rex window new -s $REX_SESSION nvim -c $PWD --focus=false -- $nvim_cmd >/dev/null
    or return 1
    rex window new -s $REX_SESSION btop -c $PWD --focus=false -- btop --preset 1 >/dev/null

    pi
end
