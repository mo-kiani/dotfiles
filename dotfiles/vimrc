"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
"'''''''''''''''                    Settings                    ''''''''''''''''
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


"'''''''''''''''                     Colors                     ''''''''''''''''

syntax enable  " Enable syntax highlighting/coloring

" Set colorscheme
set background=dark
set termguicolors  " enhances colors
colorscheme desert  " in case gruvbox is not available use most similiar builtin
silent! colorscheme gruvbox  " Set colorscheme to The GOAT: Greatest Of All Time

" Use gruvbox dark colorscheme in internal terminal (:term)
let g:terminal_ansi_colors = [
  \'#282828', '#cc241d', '#98971a', '#d79921',
  \'#458588', '#b16286', '#689d6a', '#a89984',
  \'#928374', '#fb4934', '#b8bb26', '#fabd2f',
  \'#83a598', '#d3869b', '#8ec07c', '#ebdbb2' ]


"'''''''''''''''                Styling & Layout                ''''''''''''''''

" Show partial normal-mode commands at botton-right corner
set showcmd

" Show line/column/etc info at bottom-right corner (covered by airline)
set ruler

" Show current line number at current line and relative offset at other lines
set number
set relativenumber

" Highlight current line
set cursorline

" Keep cursorline in the middle of the page unless at beginning or end of file
set scrolloff=999

" Visual guide to help keep lines to a maximum of 80 characters long
set colorcolumn=81

" Set intuitive default positions for splits (:sp and :vs and similar)
set splitright
set splitbelow

" Change cursor style based on current mode
let &t_EI = "\e[4 q"  " underline in normal mode
let &t_SI = "\e[6 q"  " vertical line on left in insert mode
let &t_SR = "\e[2 q"  " block in replace mode
" Reset the cursor to normal mode on start
augroup my_reset_cursor_on_start
    autocmd!
    autocmd VimEnter * silent !echo -e "\e[4 q"
augroup END


"'''''''''''''''                     Editing                    ''''''''''''''''

" Enable mouse interactivity in all modes
set mouse=a

" Prevent vim from blocking backspace during certain boundaries in insert mode
set backspace=start,indent,eol

" Indent using 4 spaces (PEP 8)
set expandtab
set softtabstop=4

" Set shifting commands to match indenting style
set shiftwidth=4  " This is for <<, >> and == to work
set shiftround  " Shift commands will round spacing to multiples of shiftwidth

" Automatic and filetype-sensitive indenting
set autoindent
set smartindent
filetype indent on


"'''''''''''''''               Navigation & Search              ''''''''''''''''

" Search highlighting
set hlsearch  " Highlight all search matches
set incsearch  " Highlight searches as search is typed
noh  " Make sure nothing is highlighted to begin with

" Case-sensitive search if any capitals are used, case-insensitive otherwise
set ignorecase
set smartcase

" Nice and intuitive tab-completion behavior with menu
set wildmenu
set wildmode=longest:full,full


"'''''''''''''''                 Data and Files                 ''''''''''''''''

" Use special dirs under ~/.vim for swap and backup files respectively
" This is just to reduce clutter while working
" Default to current working directory like usual if special dir is unavailable
" '//' triggers filename expansion to prevent namespace clashes
set directory=~/.vim/swap//,.
set backupdir=~/.vim/backup//,.


"'''''''''''''''                      Netrw                     ''''''''''''''''

set hidden  " This is here to prevent splits when using :Ex on a modified file
let g:netrw_banner = 0  " Do not show the netrw banner by default
let g:netrw_liststyle = 3  " tree view
let g:netrw_browse_split = 0  " Use curr win for Ex; can use Lex for split view
let g:netrw_winsize = -16  " '-' indicates absolute value rather than percent
let g:netrw_preview = 1  " Split file previews vertically
let g:netrw_keepdir = 0  " fixes error when moving files upward
let g:netrw_localcopydircmd = 'cp -r'  " Enable recursive copying of dirs
" Highlight marked files like a visual selection
highlight! link netrwMarkFile Visual

" Below are a set of functions for improving on built-in netrw behaviour
" Due to shared state they should be used exclusively (ie. don't :Lex directly)
" The focus here is only on Ex and Lex; variants such as Vex are not considered

" Shared State
" w:my_netrw_prev_buffer: The buf# each Ex instance was last opened over
" t:my_netrw_lex_win_id: The window id of the Lex window, each tab gets its own
" t:my_netrw_lex_return_win_id: The window id Lex was last opened from
" g:netrw_chgwin: Default window for <cr> in Netrw, see ':help netrw_chgwin'

" Keep state updated as windows are entered
function! MyUpdateNetrwState()
    " Initialize Lex win_id to empty str indicating Lex is not open
    if !exists('t:my_netrw_lex_win_id')
        let t:my_netrw_lex_win_id = ''
    endif
    " Initialize Lex return win_id to empty str indicating no return window set
    if !exists('t:my_netrw_lex_return_win_id')
        let t:my_netrw_lex_return_win_id = ''
    endif
    " Update in case the Lex window was closed
    if win_id2win(t:my_netrw_lex_win_id) == 0
        let t:my_netrw_lex_win_id = ''
    endif
    " Update in case the Lex return window was closed
    if win_id2win(t:my_netrw_lex_return_win_id) == 0
        let t:my_netrw_lex_return_win_id = ''
    endif
    " Update g:netrw_chgwin so that files open in the correct window with <cr>
    if t:my_netrw_lex_win_id == win_getid()
        " When in Lex, open files in return win. If no return win, use next win.
        if t:my_netrw_lex_return_win_id == ''
            let g:netrw_chgwin = win_id2win(win_getid())+1
        else
            let g:netrw_chgwin = win_id2win(t:my_netrw_lex_return_win_id)
        endif
    else
        " Set g:netrw_chgwin to make files open in the same window when in Ex
        " We do this even when we aren't in Ex, just as long as we aren't in Lex
        " That's because launching Ex won't trigger WinEnter, so we pre-empt
        let g:netrw_chgwin = win_id2win(win_getid())
    endif
endfunction
augroup my_keep_netrw_state_updated
    autocmd!
    autocmd WinEnter * :call MyUpdateNetrwState()
    autocmd VimEnter * :call MyUpdateNetrwState()  " needed for initial window
augroup END

" Open Ex if not already in Netrw
function! MyOpenEx()
    if &filetype != 'netrw'
        let w:my_netrw_prev_buffer = bufnr('%')
        Explore
    endif
endfunction

" Open Lex if it is not already open or go to existing Lex
function! MyOpenLex()
    let l:invoking_window = win_getid()
    " Open Lex if needed or go to existing one
    if t:my_netrw_lex_win_id == ''
        Lexplore
        " Under certain conditions, g:netrw_winsize doesn't take effect
        "     One example is during a recovery of an altered Lex (ie. with :e)
        vertical resize 16
        let t:my_netrw_lex_win_id = win_getid()
    else
        call win_gotoid(t:my_netrw_lex_win_id)
        " Recover Lex window if for some reason it was altered (ie. with :e)
        if &filetype != 'netrw'
            let t:my_netrw_lex_win_id = ''
            call MyOpenLex()
        endif
    endif
    " Update return window (only if invoked while not already on Lex)
    if t:my_netrw_lex_win_id != l:invoking_window
        let t:my_netrw_lex_return_win_id = l:invoking_window
        let g:netrw_chgwin = win_id2win(l:invoking_window)
    endif
endfunction

" Return to the buffer you were in before you used Ex in this window
"     If there was no buffer (ie. because you used 'vim .'), quit the window
"     Does nothing if not in an Ex instance and does nothing in the Lex instance
function! MyCloseEx()
    if &filetype == 'netrw'
        if t:my_netrw_lex_win_id != win_getid()
            if exists('w:my_netrw_prev_buffer')
                execute 'buffer ' . w:my_netrw_prev_buffer
            else
                quit
            endif
        endif
    endif
endfunction

" Go to the last window that Lex was opened from
"     If no such window exists and you are on Lex, go to the window after Lex
"     If no such window exists and you aren't on Lex, stay where you are
function! MyReturnFromLex()
    if t:my_netrw_lex_return_win_id != ''
        call win_gotoid(t:my_netrw_lex_return_win_id)
    else
        if t:my_netrw_lex_win_id == win_getid()
            wincmd w
        endif
    endif
endfunction

" Return from Netrw (either Lex or Ex) to whatever you were doing before
function! MyReturnFromNetrw()
    if t:my_netrw_lex_win_id == win_getid()
        call MyReturnFromLex()
    else
        call MyCloseEx()
    endif
endfunction

" Close Lex if it is open
function! MyCloseLex()
    if t:my_netrw_lex_win_id != ''
        call MyOpenLex()
        Lexplore
        call MyReturnFromLex()
    endif
endfunction

" Close Lex or Ex if you are in one
function! MyCloseNetrw()
    if t:my_netrw_lex_win_id == win_getid()
        call MyCloseLex()
    else
        call MyCloseEx()
    endif
endfunction

" Toggle into Ex or out of either Ex or Lex
function! MyToggleNetrw()
    if &filetype == 'netrw'
        call MyCloseNetrw()
    else
        call MyOpenEx()
    endif
endfunction


"'''''''''''''''                     Airline                    ''''''''''''''''

" Enable and configure tabline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

" Unicode Symbols
let g:airline_symbols = {}
let g:airline_symbols.readonly = '◉'

" Use NerdFont glyphs if available
if !empty($NERD_FONT)
    let g:airline_powerline_fonts = 1
    " Separators
    let g:airline_left_sep = ''
    let g:airline_left_alt_sep = ''
    let g:airline_right_sep = ''
    let g:airline_right_alt_sep = ''
    let g:airline#extensions#tabline#left_sep = ''
    let g:airline#extensions#tabline#left_alt_sep = ''
    let g:airline#extensions#tabline#right_sep = ''
    let g:airline#extensions#tabline#right_alt_sep = ''
    " Symbols
    let g:airline_symbols.readonly = ''
endif


"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
"'''''''''''''''                    Bindings                    ''''''''''''''''
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

" Set leader to space-bar
let mapleader = "\<Space>"

" Turn off highlights with double <ESC>
nnoremap <esc><esc> :noh<cr>

" Easy Session Management
nnoremap <leader>m :mksession 
nnoremap <leader>M :mksession! .session.vim<cr>
nnoremap <leader>s :source 
nnoremap <leader>S :source .session.vim<cr>

" Open drawer-like terminal just like in VSCode
nnoremap <leader>t :botright term ++rows=12<cr>
" Jump to bottom window (generally meant for drawer-like terminal)
nnoremap <leader>j 99<c-w>j
" Close bottom window (generally meant for drawer-like terminal)
nnoremap <leader>J 99<c-w>j<c-w>:q!<cr>

" Shortcuts to open/close Netrw
nnoremap <leader>f :call MyToggleNetrw()<cr>
nnoremap <leader>h :call MyOpenLex()<cr>
nnoremap <leader>H :call MyCloseLex()<cr>

" Netrw-specific keybindings
function! MyNetrwMapping()
    " cancel out of Netrw
    nmap <buffer> qq :call MyCloseNetrw()<cr>
    " return from Netrw to whatever I was doing before
    nmap <buffer> h :call MyReturnFromNetrw()<cr>
    " open file but stay in Lex, kind of like an improved preview
    nmap <buffer> l <cr>:call MyOpenLex()<cr>
    " open and go to file, close Lex behind
    nmap <buffer> L <cr>:call MyCloseLex()<cr>

    " go up one directory
    nmap <buffer> , -^
    " go into highlighted directory
    nmap <buffer> ; gn

    " set target easily
    nmap <buffer> . mt
    " mark/unmark files easily
    nmap <buffer> y mf
    nmap <buffer> <tab> mf
    " unmark all files easily
    nmap <buffer> Y mu
    nmap <buffer> <s-tab> mu

    " create a new file more conveniently
    nmap <buffer> f %
    " source the currently highlighted file
    nmap <buffer> z <cr>:source %<cr>
endfunction
" Allow Netrw-specific keybindings
augroup my_netrw_mapping
    autocmd!
    autocmd filetype netrw call MyNetrwMapping()
augroup END
