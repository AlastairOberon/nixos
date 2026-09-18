# Run fastfetch only in interactive terminal sessions (skip in Neovim/scripts/dumb terms)
if [[ -o interactive ]] && [[ -t 1 ]] && [[ "$TERM" != "dumb" ]] && [[ -z "$NVIM" && -z "$VIM" ]]; then
    if command -v fastfetch &>/dev/null; then
        local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch.cache"
        setopt extendedglob
        if [[ -s "$cache_file" ]]; then
            # Display cached fetch instantaneously (~2ms)
            cat "$cache_file"
            # Asynchronously refresh cache in the background if older than 15 minutes
            if [[ -n ${cache_file}(#qN.mm+15) ]]; then
                (fastfetch > "$cache_file.tmp" 2>/dev/null && mv -f "$cache_file.tmp" "$cache_file") &!
            fi
        else
            # First launch: generate cache and display
            fastfetch | tee "$cache_file"
        fi
    fi
fi


