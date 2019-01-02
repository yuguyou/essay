set tabstop=2 "TAB建宽度
set shiftwidth=2 "统一缩进为4 
set softtabstop=2 "统一缩进为4 
set list
set listchars=tab:>-,trail:-

set nobk
set helplang=cn
set hls-
set ignorecase

set expandtab "将tab设置为四个空格 (%s/\t/    /g) 

set autoindent "缩进值与上行相等
set cindent "自动缩进
set smartindent
set incsearch
set hlsearch
set number
set guifont=Consolas:h18:cANST
set guifontwide=DotumChe:h18:cANST
set ruler  "设置标尺
set clipboard+=unnamed "共享剪贴板
set encoding=utf-8

filetype plugin on "允许插件

"特殊文件类型设置
autocmd FileType python set shiftwidth=4 | set softtabstop=4 | set tabstop=4 | set expandtab

if filereadable(".virc")
    source .virc
endif
