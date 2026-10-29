function ws --description 'Set up the current herdr workspace: pi in this tab, nvim in a second one'
    herdr workspace rename $HERDR_WORKSPACE_ID (path basename $PWD) >/dev/null
    herdr tab rename $HERDR_TAB_ID pi >/dev/null

    set -l nvim_pane (herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd $PWD --label nvim --no-focus | jq -r .result.root_pane.pane_id)
    test -n "$nvim_pane"; or return 1

    # Open on the review of uncommitted changes when there are some
    set -l nvim_cmd nvim
    if test -n "$(git status --porcelain 2>/dev/null)"
        set nvim_cmd nvim +CodeDiff
    end
    herdr pane run $nvim_pane $nvim_cmd >/dev/null

    pi
end
