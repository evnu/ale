" Author: Magnus Ottenklinger - https://github.com/evnu

function! ale_linters#erlang#erlc#Handle(buffer, lines)
  " Matches patterns like the following:
  "
  " error.erl:4: variable 'B' is unbound
  " error.erl:3: Warning: function main/0 is unused
  " error.erl:4: Warning: variable 'A' is unused
  let l:pattern = '\v^([^:]+):(\d+): (Warning: )?(.+)$'

  " parse_transforms are a special case. The error message does not indicate a location:
  " error.erl: undefined parse transform 'some_parse_transform'
  let l:pattern_parse_transform = '\v(undefined parse transform .*)$'
  let l:output = []

  let l:pattern_no_module_definition = '\v(no module definition)$'
  let l:pattern_unused = '\v(.* is unused)$'

  let l:is_hrl = expand('%:e') ==# 'hrl'

  for l:line in a:lines
    let l:match = matchlist(l:line, l:pattern)
    let l:match_parse_transform = matchlist(l:line, l:pattern_parse_transform)

    " Determine if the output indicates an error. We distinguish between two cases:
    "
    " 1) normal errors match l:pattern
    " 2) parse_transform errors match l:pattern_parse_transform
    "
    " If none of the patterns above match, the line can be ignored
    if len(l:match) == 0 " not a 'normal' warning or error
        if len(l:match_parse_transform) == 0 " also not a parse_transform error
            continue
        endif

        let l:text = l:match_parse_transform[0]
        call add(l:output, {
                    \   'bufnr': a:buffer,
                    \   'lnum': 0,
                    \   'vcol': 0,
                    \   'col': 0,
                    \   'type': 'E',
                    \   'text': l:text,
                    \   'nr': -1,
                    \})
        continue
    endif

    let l:line = l:match[2]
    let l:warning_or_text = l:match[3]
    let l:text = l:match[4]

    " If this file is a header .hrl, ignore the following expected messages:
    " - 'no module definition'
    " - 'X is unused'
    if l:is_hrl &&
                \ (match(l:text, l:pattern_no_module_definition) != -1 ||
                \  match(l:text, l:pattern_unused) != -1)
        continue
    endif

    if !empty(l:warning_or_text)
        let l:type = 'W'
    else
        let l:type = 'E'
    endif

    " vcol is Needed to indicate that the column is a character.
    call add(l:output, {
    \   'bufnr': a:buffer,
    \   'lnum': l:line,
    \   'vcol': 0,
    \   'col': 0,
    \   'type': l:type,
    \   'text': l:text,
    \   'nr': -1,
    \})
  endfor

  return l:output
endfunction

call ale#linter#Define('erlang', {
      \ 'name': 'erlc',
      \ 'executable': 'erlc',
      \ 'command': g:ale#util#stdin_wrapper . ' .erl erlc '
      \             . get(g:, 'ale_erlang_erlc_flags', ''),
      \ 'callback': 'ale_linters#erlang#erlc#Handle' })
