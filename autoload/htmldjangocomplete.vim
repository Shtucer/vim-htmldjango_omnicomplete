" Vim completion script
" Language: htmldjango
" Maintainer:   Michael Brown
" Last Change:  Sun 22 Apr 2012 01:29:23 EST
" Omnicomplete for django template taga/variables/filters
"
"django filters triggered on {{variable|<here>}}
let s:django_filters = []
"django tags triggered on {% <here> %}
let s:django_tags = []
"triggered on {{ <here> }}
let s:django_variables = []
"
function! s:load_django_completes ()
if has('python')
    call s:load_libs()
endif
endfunction

function! htmldjangocomplete#CompleteDjango(findstart, base)
    "findstart = 1 when we need to get the text length
    "
    call s:load_libs()

    if a:findstart == 1
        " locate the start of the word
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '\a'
          let start -= 1
        endwhile
        return start
    "findstart = 0 when we need to return the list of completions
    else
        "get context look for {% {{ and |
        let line = getline('.')
        let start = col('.') -1

        "check for {% load %}
        if match(line, '{% load ') >  -1
            execute "python htmldjangocomplete('load', '" . a:base . "')"
            return g:htmldjangocomplete_completions
        endif

        while start > 0
            if line[start] == ':' && s:in_django(line,start) == 1
                execute "python htmldjangocomplete('variable', '" . a:base . "')"
                return g:htmldjangocomplete_completions
            elseif line[start] == '|' && s:in_django(line,start)
                execute "python htmldjangocomplete('filter', '" . a:base . "')"
                return g:htmldjangocomplete_completions
            elseif line[start] == '{' && line[start -1] == '{'
                execute "python htmldjangocomplete('variable', '" . a:base . "')"
                return g:htmldjangocomplete_completions
            elseif line[start] == '%' && line[start -1] == '{'
                execute "python htmldjangocomplete('tag', '" . a:base . "')"
                return g:htmldjangocomplete_completions
            else
                let start -= 1
            endif
        endwhile

        "fallback to htmlcomplete TODO This doesn't work as expected.
        "Might need to turn off some doctype setting.
        "
        "call htmlcomplete#CompleteTags(1, a:base)
        "return htmlcomplete#CompleteTags(0, a:base)
    endif
endfunction

"TODO This could probably be neater with an index check. need string check!
function! s:in_django(l,s)
    let line = a:l
    let start = a:s
    while start > 0
        if line[start] == '}'
            return 0
        elseif line[start] == '{'
            return 1
        endif
        let start -= 1
    endwhile
    return 0
endfunction

let g:htmldjangocomplete_completions = []
function! s:load_libs()
if has('python')
python << EOF
DEBUG = False
import vim
from django.template import import_library, get_library
from django.template import get_templatetags_modules
import re
from operator import itemgetter
import pkgutil
import os


def get_tag_libraries():
    opts = []
    for module in get_templatetags_modules():
        mod = __import__(module,fromlist=['foo'])
        for l,m,i in pkgutil.iter_modules([os.path.dirname(mod.__file__)]):
            opts.append({'word':m,'menu':mod.__name__})

    return opts


def _get_doc(doc, name):
    if doc:
        return doc.replace('"',' ').replace("'",' ')
    return '%s: no doc' % name

def _get_opt_dict(lib,t,libname=''):
    opts = getattr(lib,t)
    return [
    {'word':f, 'info': _get_doc(opts[f].__doc__,f),'menu':libname} \
    for f in opts.keys()]

htmldjango_opts = {}


htmldjango_opts['load'] = get_tag_libraries()

def_filters = import_library('django.template.defaultfilters')
htmldjango_opts['filter'] = _get_opt_dict(def_filters,'filters','default')
def_tags = import_library('django.template.defaulttags')
htmldjango_opts['tag'] = _get_opt_dict(def_tags,'tags','default')

cb = vim.current.buffer
for line in cb:
    m =  re.compile('{% load (.*)%}').match(line)
    if m:
        for lib in m.groups()[0].rstrip().split(' '):
            try:
                l = get_library(lib)
                htmldjango_opts['filter'] += _get_opt_dict(l,'filters',lib)
                htmldjango_opts['tag'] += _get_opt_dict(l,'tags',lib)
                #print "LOADED: %s" % lib
            except Exception as e:
                if DEBUG:
                    raise e

#TODO I may be able to populate RequestContext via middleware component
htmldjango_opts['variable'] = []

def htmldjangocomplete(context,match):
    all = htmldjango_opts[context]

    vim.command("silent let g:htmldjangocomplete_completions = []")

    dictstr = '['
    # have to do this for double quoting

    all = [a for a in all if a['word'].startswith(match)]
    all = sorted(all, key=itemgetter('word'))

    for cmpl in all:
        dictstr += '{'
        for x in cmpl: dictstr += '"%s":"%s",' % (x,cmpl[x])
        dictstr += '"icase":0},'
    if dictstr[-1] == ',': dictstr = dictstr[:-1]
    dictstr += ']'
    vim.command("silent let g:htmldjangocomplete_completions = %s" % dictstr)
EOF
endif
endfunction

function! TestLoadLibs()
    call s:load_libs()
endfunction

" vim:set foldmethod=marker:
