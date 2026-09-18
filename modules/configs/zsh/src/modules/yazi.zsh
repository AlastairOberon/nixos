# Yazi wrapper to sync working directory on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}

