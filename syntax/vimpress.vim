if version < 600
 syntax clear
elseif exists("b:current_syntax")
 finish
endif
sy match  blogeditorEntry       "^ *[0-9]*\t.*$"
sy match  blogeditorComment     '^".*$'
sy match  blogeditorIdent       '^".*:'
hi link blogeditorComment     Comment
hi link blogeditorEntry       Directory
hi link blogeditorIdent       Function
syntax include @Markdown syntax/markdown.vim
syntax region markdownCode matchgroup=blogeditorComment start=+"========== Content ==========+ end=+"========== Content ==========+ contains=@Markdown
let b:current_syntax = "blogsyntax"
