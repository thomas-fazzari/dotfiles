function ws --description 'Set up my default Herdr space in the current one'
    set -q HC_TERMINAL_ID; or begin
        echo "ws: not in a Herdr app terminal" >&2
        return 1
    end

    # The space names itself after the repo, so only tabs are named
    set -l labels (hc get $HC_TERMINAL_ID --json | jq -r '.labels["herdr.space"], .labels["herdr.tab"]')
    set -l space $labels[1]
    set -l tab $labels[2]
    test -n "$space" -a "$space" != null; or begin
        echo "ws: this terminal is not in a Herdr space" >&2
        return 1
    end

    # Open on the review of uncommitted changes when there are some
    set -l nvim_cmd nvim
    if test -n "$(git status --porcelain 2>/dev/null)"
        set nvim_cmd nvim +CodeDiff
    end

    herdr-app do tab.rename --id $tab --name pi >/dev/null
    herdr-app do tab.new --space $space --folder $PWD --name nvim --argv (jq -cn '$ARGS.positional' --args $nvim_cmd) >/dev/null
    or return 1
    herdr-app do tab.new --space $space --folder $PWD --name btop --argv '["btop","--preset","1"]' >/dev/null
    herdr-app do tab.select --id $tab >/dev/null

    pi
end
