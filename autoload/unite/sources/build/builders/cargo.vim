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
    return s:analyze_error(a:string, unite#util#substitute_path_separator(getcwd()))
  endif
  if a:string =~ 'warning:'
    return s:analyze_warning(a:string, unite#util#substitute_path_separator(getcwd()))
  endif
  return { 'type': 'message', 'text': a:string }
endfunction " }}}

function! s:analyze_error(string, current_dir) " {{{
  if a:string =~ '^error:'
    return { 'type': 'message', 'text': a:string }
  endif

  let list = split(a:string, ' ')
  if empty(list)
    return { 'type': 'message', 'text': a:string }
  endif

  let candidate = {}

  let token  = list[0][:-2]
  let remains = join(list[3:-1])

  let [filename, line, column] = split(token, ':')
  if !filereadable(filename) && '\<\f\+:'
    return { 'type': 'message', 'text': a:string }
  endif
 
  let candidate.filename = (filename !~ '^/\|\a\+:/') ? a:current_dir . '/' . filename : filename
  if line  =~ '^\d\+$'
    let candidate.line = line
  endif
  if column =~ '^\d\+$'
    let candidate.col = column
  endif

  let candidate.text = remains
  let candidate.type = 'error'

  return candidate
endfunction " }}}

function! s:analyze_warning(string, current_dir) " {{{
  if a:string =~ '^warning:'
    return { 'type': 'message', 'text': a:string }
  endif

  let list = split(a:string, ' ')
  if empty(list)
    return { 'type': 'message', 'text': a:string }
  endif

  let candidate = {}

  let token  = list[0][:-2]
  let remains = join(list[3:-1])

  let [filename, line, column] = split(token, ':')
  if !filereadable(filename) && '\<\f\+:'
    return { 'type': 'message', 'text': a:string }
  endif
 
  let candidate.filename = (filename !~ '^/\|\a\+:/') ? a:current_dir . '/' . filename : filename
  if line  =~ '^\d\+$'
    let candidate.line = line
  endif
  if column =~ '^\d\+$'
    let candidate.col = column
  endif

  let candidate.text = remains
  let candidate.type = 'warning'

  return candidate
endfunction " }}}
