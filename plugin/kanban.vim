" kanban.vim - Extends VimWiki with pomodoro items
" Maintainer:   Gerhard Gappmeier
" Version:      1.0

if exists("g:loaded_kanban")
    finish
endif
let g:loaded_kanban = 1

" A pomodoro item is an extension to a VimWiki todo item.
" and loooks like this.
" Example: * [o] [M] test bla (19/08/15,20/08/15,10)
"             ^   ^  ^^^^^^^^  ^^^^^^^^ ^^^^^^^^ ^^
"             |   |  |         |        |        +-- Working minutes
"             |   |  |         |        +-- End Date
"             |   |  |         |
"             |   |  |         +-- Start Date
"             |   |  +-- Description
"             |   +-- Pomodoro Ticket Size: S, M, L
"             +-- Todo-List-Checkbox
"
" This is used to track Kanban tickets using the pomodoro method.
" See https://en.wikipedia.org/wiki/Pomodoro_Technique
" Using this plugin you can start a pomodoro timer for the item
" below the cursor. This will insert the start date into the parentheses
" if it does not already exist. Completing one such ticket can require
" multiple pomodoro cycles. The working time is tracked and the last field.
" When the ticket is completed it will insert the end date.
" This way you not only have an overview about your tickets, you can also see
" how many days you needed to complete a ticket and how long you have worked
" on it effectively.
" This plugin works together with an external Pomodoro timer tool, which
" visually presents the pomodoro time as a countdown. This tool can also be
" used to track the break times.

" Test patterns
" * [ ] [ ] this is empty (,,)
" * [.] [M] started (19/08/15,,)
" * [o] [M] started2 (19/08/15,,25)
" * [O] [M] started3 (19/08/15,,50)
" * [X] [M] done (19/08/15,19/08/15,100)
" output
function! ParsePomodoroItem()
    " use very no magic to make this more robust
    let dateregex ='\(\d\d/\d\d/\d\d\)'
    let regex = '\V\( \** [\[ .oOX]]\) [\(\[ SML]\)] \(\[A-Za-z0-9_ ]\+\) ('.dateregex.'\?,'.dateregex.'\?,\(\d\*\))'
    let line=getline('.')
    let line=getline(41)
    echo "regex=".regex
    echo "line='".line.''''
    let cap = matchlist(line, regex)
    if !empty(cap)
        let i = 0
        for c in cap
            echo "cap[".i."] = ".c
            let i+=1
        endfor
        echo "match"
        let todolist=cap[1]
        let ticketsize=cap[2]
        let title=cap[3]
        let startdate=cap[4]
        let enddate=cap[5]
        let time=cap[6]
        " compose new line
        let line=todolist.' ['.ticketsize.'] '.title.
                    \' ('.startdate.','.enddate.','.time.')'
        call append(42, line)
    else
        echo "no match"
    endif
endfunction
