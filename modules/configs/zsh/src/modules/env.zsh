export PATH="$HOME/.local/bin:$PATH"

#External env files
[[ -f ~/.local/bin/env ]] && source ~/.local/bin/env

#GO
export PATH=$PATH:$(go env GOPATH)/bin

#NVIM
export XDG_DATA_HOME="$HOME/.local/share"

#QMLStuff
export PATH=/usr/lib/qt6/bin:$PATH

#Default Editor
export EDITOR="nvim"

#Zoxide
eval "$(zoxide init zsh)"

#CUDA/GPU

export CUDA_HOME=/opt/cuda
export PATH=$PATH:$CUDA_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64

#Browser
export BROWSER="zen-browser"

#TensorFlow
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/.venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib/

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
