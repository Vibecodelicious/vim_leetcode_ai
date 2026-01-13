" vim_leetcode_ai - AI assistant with interactive slideshow for code editing
" Maintainer: Basil
" License: MIT

if exists('g:loaded_vim_leetcode_ai')
  finish
endif
let g:loaded_vim_leetcode_ai = 1

" Require Neovim 0.9+
if !has('nvim-0.9')
  echohl ErrorMsg
  echomsg 'vim_leetcode_ai requires Neovim 0.9 or later'
  echohl None
  finish
endif

" Define user commands
command! AIOpen lua require('vim_leetcode_ai').open()
command! AIClose lua require('vim_leetcode_ai').close()
command! AIRestart lua require('vim_leetcode_ai').restart()
