# completion-tmux
tmux panels autocompletion source for [completion-nvim](https://github.com/nvim-lua/completion-nvim)



## Installation

Use your favorite plugin manager to install it, and add `tmux` to the chain completion list:

```vimL
Plug 'albertoCaroM/completion-tmux'

let g:completion_chain_complete_list = {
      \ 'default': {'comment': [], 
      \ 'default': [{'complete_items': [ 'lsp', 'tmux' ]},
      \  {'mode': '<c-p>'}, {'mode': '<c-n>'}]}}

```
