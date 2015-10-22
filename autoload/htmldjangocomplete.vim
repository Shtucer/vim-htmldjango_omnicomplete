" Vim completion script
" Language: htmldjango
" Maintainer:   Michael Brown
" Last Change:  Sun 13 May 2012 16:39:45 EST
" Version: 0.9.2
" Omnicomplete for django template taga/variables/filters
" {{{1 Environment Settings
if !exists('g:htmldjangocomplete_html_flavour')
    " :verbose function htmlcomplete#CheckDoctype for details
    " No html5!
    "'html401t' 'xhtml10s' 'html32' 'html40t' 'html40f' 'html40s'
    "'html401t' 'html401f' 'html401s' 'xhtml10t' 'xhtml10f' 'xhtml10s'
    "'xhtml11'
    let g:htmldjangocomplete_html_flavour = 'xhtml11'
endif

if !has('python') && !has('python3')
    throw "htmldjango_omnicomplete requires Vim with support +python or +python3"
endif

"Allow settings of DEBUG
if !exists('g:htmldjangocomplete_debug')
    let g:htmldjangocomplete_debug = 1
endif

if !exists('g:htmldjangocomplete_python')
    let g:htmldjangocomplete_python=3
endif

if g:htmldjangocomplete_python==3
    let s:cmd_python='python3'
    let s:file_python='py3file'
elseif g:htmldjangocomplete_python==3
    let s:cmd_python='python'
    let s:file_python='pyfile'
endif
let s:script_path = fnameescape(expand('<sfile>:p:h:h'))
execute 'command! -nargs=1 DjPython '.s:cmd_python.' <args>'

"{{{1 The actual omnifunc
function! htmldjangocomplete#CompleteDjango(findstart, base)
    "{{{2 findstart = 1 when we need to get the text length
    "
    if a:findstart == 1

        "Fallback to htmlcomplete
        if searchpair('{{','','}}','nc') == 0 && searchpair('{%',"",'%}','nc') == 0
            if !exists('b:html_doctype')
                let b:html_doctype = 1
                let b:html_omni_flavor = g:htmldjangocomplete_html_flavour
            endif
            return htmlcomplete#CompleteTags(a:findstart,a:base)
        endif

        " locate the start of the word
        let line = getline('.')
        let start = col('.') - 1
        "special case for {% extends %} {% import %} needs to grab /'s
        "TODO make this match more flexible. It needs to know its in a string
        "also need to handle inline imports
        if s:get_context() == 'extends'|| s:get_context() == 'include'
            while start > 0 && line[start - 1] != '"' && line[start -1] != "'"
                        \ && line[start -1] != ' '
            let start -= 1
            endwhile
            return start
        endif
        "
        "default <word> case
        while start > 0 && line[start - 1] =~ '\a'
          let start -= 1
        endwhile
        return start
    "{{{2 findstart = 0 when we need to return the list of completions
    else
        "Fallback to htmlcomplete
        if searchpair('{{','','}}','nc') == 0 && searchpair('{%',"",'%}','nc') == 0
            let matches = htmlcomplete#CompleteTags(a:findstart,a:base)
            "suppress all DOCTYPE matches
            call filter(matches, 'stridx(v:val["word"],"DOCTYPE") == -1')
            return matches
        endif

        let context = s:get_context()

        if context == 'extends' || context == 'include'
            let context = 'template'
        endif

        "TODO: Reduce load always nature of this plugin
        call s:load_libs()
        "get context look for {% {{ and |
        let line = getline('.')
        let start = col('.') -1

        " Special case for extends and import
        " TODO 'filter' should really just be string filters
        if index(['template','load','url','filter','block', 'static'],context) != -1
            DjPython htmldjangocomplete(vim.eval("context"), vim.eval("a:base"))
            return g:htmldjangocomplete_completions
        endif

        while start > 0
            if line[start] == ':' && s:in_django(line,start) == 1
                DjPython htmldjangocomplete('variable',vim.eval("a:base") )
                return g:htmldjangocomplete_completions
            elseif line[start] == '|' && s:in_django(line,start)
                DjPython htmldjangocomplete('filter', vim.eval("a:base"))
                return g:htmldjangocomplete_completions
            elseif line[start] == '{' && line[start -1] == '{'
                DjPython htmldjangocomplete('variable', vim.eval("a:base"))
                return g:htmldjangocomplete_completions
            elseif line[start] == '%' && line[start -1] == '{'
                DjPython htmldjangocomplete('tag', vim.eval("a:base"))
                return g:htmldjangocomplete_completions
            else
                let start -= 1
            endif
        endwhile

        return [ {'word': "nomatch"} ]
        "fallback to htmlcomplete TODO This doesn't work as expected.
        "Might need to turn off some doctype setting.
        "
        "call htmlcomplete#CompleteTags(1, a:base)
        "return htmlcomplete#CompleteTags(0, a:base)
    endif
endfunction

"Supporting vim functions {{{1
function! s:get_context()
    let curpos = getpos('.')
    let line = getline('.')

    "tags
    let starttag = searchpairpos('{%', '', '%}', 'bn')
    if starttag != [0,0]
        let fragment = line[starttag[1]:curpos[2]]
        return split(fragment,' ')[1]
    endif

    return "other"
endfunction

"TODO This could probably be neater with an index check. need to get strings
"working
function! s:in_django(l,s)
    let line = a:l
    let start = a:s
    while start >= 0
        if line[start] == '}'
            return 0
        elseif line[start] == '{'
            return 1
        endif
        let start -= 1
    endwhile
    return 0
endfunction

"Python section {{{1
"imports {{{2
let g:htmldjangocomplete_completions = []
function! s:load_libs()
    execute s:file_python.' '.s:script_path.'/load_libs.py'
endfunction
" Test Area {{{1
function! TestLoadLibs()
    call s:load_libs()
endfunction

function! HtmlDjangoDebug(on)
    if a:on
        echo "adding Breakpoint"
        breakadd func htmldjangocomplete#CompleteDjango
    else
        echo "remove Breakpoint"
        breakdel func htmldjangocomplete#CompleteDjango
    endif
endfunction
" vim:set foldmethod=marker:
