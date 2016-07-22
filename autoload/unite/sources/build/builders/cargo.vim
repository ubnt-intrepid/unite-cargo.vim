"===============================================================================
" File: cargo.vim
" AUTHOR: Yusuke Sasaki <yusuke.sasaki.nuem at gmail.com>
" License: MIT license
"===============================================================================

" Variables {{{
call unite#util#set_default('g:unite_builder_cargo_command', 'cargo')
" }}}

function! unite#sources#build#builders#cargo#define() " {{{
  return executable(unite#util#expand(g:unite_builder_cargo_command))
          \ ? s:builder 
          \ : []
endfunction " }}}

let s:builder = {
  \ 'name': 'cargo',
  \ 'description': 'Cargo package manager'
  \ }

function! s:builder.detect(args, context) " {{{
  return filereadable('Cargo.toml')
endfunction " }}}

function! s:builder.initialize(args, context) " {{{
  let a:context.builder__current_dir =
        \ unite#util#substitute_path_separator(getcwd()) 
  return g:unite_builder_cargo_command . " build -q " . join(a:args)
endfunction  " }}}

function! s:builder.parse(string, context) " {{{
  if a:string =~ 'error:'
    return s:analyze_error(a:string, a:context, unite#util#substitute_path_separator(getcwd()))
  endif
  return { 'type': 'message', 'text': a:string }
endfunction " }}}

function! s:analyze_error(string, context, current_dir) " {{{
  let string = a:string

  let [word, list] = [string, split(string, ':')]
  let candidate = {}

  if empty(list)
    return { 'type': 'message', 'text': string }
  endif

  if len(word) == 1 && unite#util#is_windows()
    let candidate.word = word . list[0]
    let list = list[1:]
  endif

  let filename = unite#util#substitute_path_separator(word[:1].list[0])
  let candidate.filename = (filename !~ '^/\|\a\+:/') ? a:current_dir . '/' . filename : filename

  let list = list[1:]

  if !filereadable(filename) && '\<\f\+:'
    return { 'type': 'message', 'text': string }
  endif

  if len(list) > 0 && list[0] =~ '^\d\+$'
    let candidate.line = list[0]
    if len(list) > 1 && list[1] =~ '^\d\+$'
      let candidate.col = list[1]
      let list = list[1:]
    endif
    let list = list[1:]
  endif

  let candidate.type = 'error'
  let candidate.text = fnamemodify(filename, ':t') . ' : ' . join(list, ':')

  return candidate
endfunction " }}}
