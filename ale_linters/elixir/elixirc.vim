" Author: evnu - https://github.com/evnu

function! ale_linters#elixir#elixirc#Handle(buffer, lines) abort
    " Matches patterns like the following:
    "
    " (CompileError) apps/sim/lib/sim/server.ex:87: undefined function update_in/4
    "
    " TODO include warnings
    let l:pattern = '\v\((CompileError|SyntaxError)\) ([^:]+):([^:]+): (.+)$'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, l:pattern)
        let l:type = 'C'
        let l:text = l:match[4]

        call add(l:output, {
        \   'bufnr': a:buffer,
        \   'lnum': l:match[3] + 0,
        \   'col': 0,
        \   'type': l:type,
        \   'text': l:text,
        \})
    endfor

    return l:output
endfunction

function! ale_linters#elixir#elixirc#Command(buffer)
    return  'elixirc %s -o /tmp/%t'
endfunction

call ale#linter#Define('elixir', {
\   'name': 'elixirc',
\   'executable': 'elixirc',
\   'command_callback': 'ale_linters#elixir#elixirc#Command',
\   'callback': 'ale_linters#elixir#elixirc#Handle',
\})
