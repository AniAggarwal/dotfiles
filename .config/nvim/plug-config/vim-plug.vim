" Plugins using Vim Plug

call plug#begin()

Plug 'preservim/nerdtree' " NERDTree
Plug 'kevinhwang91/rnvimr', {'do': 'make sync'} " Ranger in nvim
Plug 'tiagofumo/vim-nerdtree-syntax-highlight' " NERDTree highlighting by filetype
Plug 'tpope/vim-surround' " Surround
Plug 'vim-airline/vim-airline' " Airline, the bottom bar
Plug 'tpope/vim-fugitive' " Fugitive, git integration
Plug 'nvim-lua/plenary.nvim' " Dependency for gitsigns
Plug 'lewis6991/gitsigns.nvim' " GitSigns, show git changes in nvim
Plug 'tpope/vim-commentary' " Commentary, comment lines
Plug 'sheerun/vim-polyglot' " Polyglot, language support
" Plug 'preservim/tagbar' " Tagbar, code outline TODO: remove once vista works
Plug 'liuchengxu/vista.vim' " Vista, symbols and tags in the sidebar
Plug 'ludovicchabant/vim-gutentags' " Gutentags, instant tag generation
Plug 'https://github.com/kassio/neoterm' " Neoterm, terminal integration
Plug 'justinmk/vim-sneak' " Sneak, fast movement
Plug 'unblevable/quick-scope' " QuickScope, quick movement within a line
Plug 'mhinz/vim-startify' " Startify, project management
Plug 'folke/which-key.nvim' " nvim whichkey, shows keybinds
Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'} " KittyNavigator, Vim keybinds for movement in Kitty terminal

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " FZF, fuzzy finder for quick searching
Plug 'junegunn/fzf.vim' " More FZF
Plug 'antoinemadec/coc-fzf' " FZF for coc

Plug 'joshdick/onedark.vim' " OneDark theme
Plug 'arcticicestudio/nord-vim' " Nord theme
Plug 'lukas-reineke/indent-blankline.nvim' " Show indentation lines
Plug 'enricobacis/vim-airline-clock' " Airline clock

Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } } " Doge, documentation generator
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} " Treesitter, required for neogen
Plug 'lewis6991/spellsitter.nvim' " Spell checking (that doesn't check code)
Plug 'metakirby5/codi.vim' " Codi, interactive virtual text

Plug 'github/copilot.vim' " Github Copilot, code completion
Plug 'neoclide/coc.nvim', {'branch': 'release'} " NeoVim Code Completion
Plug 'honza/vim-snippets' " Code snippets

" Install coc plugins
Plug 'fannheyward/coc-pyright', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-snippets', {'do': 'yarn install --frozen-lockfile'}
Plug 'iamcco/coc-vimlsp', {'do': 'yarn install --frozen-lockfile'}
Plug 'josa42/coc-sh', {'do': 'yarn install --frozen-lockfile'}

Plug 'dstein64/vim-startuptime' " Startuptime, time how long it takes to start up

Plug 'ryanoasis/vim-devicons' " Devicons, icons for files. NOTE: must be loaded LAST

call plug#end()
