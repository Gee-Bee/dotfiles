" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
Plug 'danielwe/base16-vim'
" Initialize plugin system
call plug#end()

syntax on
colorscheme base16-eighties