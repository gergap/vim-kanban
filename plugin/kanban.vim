" kanban.vim - Extends VimWiki with pomodoro items
" Maintainer:   Gerhard Gappmeier
" Version:      1.0

if exists("g:loaded_kanban")
    finish
endif
"let g:loaded_kanban = 1
let s:pomodoro_active = 0

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
function! s:ParsePomodoroItem()
    " use very no magic to make this more robust
    let dateregex ='\(\d\d/\d\d/\d\d\)'
    let regex = '\V\( \** [\[ .oOX]]\) [\(\[ SML]\)] \(\[A-Za-z0-9_ ]\+\) ('.dateregex.'\?,'.dateregex.'\?,\(\d\*\))'
    let s:lineno = line('.')
    let line=getline(s:lineno)
    "echo "regex=".regex
    "echo "lineno=".s:lineno
    "echo "line='".line.''''
    let cap = matchlist(line, regex)
    if !empty(cap)
        "let i = 0
        "for c in cap
        "    echo "cap[".i."] = ".c
        "    let i+=1
        "endfor
        "echo "match"
        let s:todolist=cap[1]
        let s:ticketsize=cap[2]
        let s:title=cap[3]
        let s:startdate=cap[4]
        let s:enddate=cap[5]
        let s:time=cap[6]
        let s:starttime=localtime()
        return 1
    else
        "echo "no match"
        return 0
    endif
endfunction

function! s:PomodoroComposeLine()
    let line=s:todolist.' ['.s:ticketsize.'] '.s:title.
                \' ('.s:startdate.','.s:enddate.','.s:time.')'
    return line
endfunction

function! PomodoroStart()
    if s:pomodoro_active
        echoerr "There is already an active pomodoro: '".s:title."'"
        return 0
    endif
    if s:ParsePomodoroItem()
        " check if there is a start date
        if s:startdate == ''
            " used todays date as startdate
            let s:startdate = strftime("%d/%m/%y")
        endif
        " compose new line
        let line = s:PomodoroComposeLine()
        call setline(s:lineno, line)
        let s:pomodoro_active = 1
        echo "Pomodoro started."
    else
        echoerr "No valid pomodoro found on this line."
    endif
endfunction

function! PomodoroStop()
    if s:pomodoro_active == 0
        echoerr "No active pomodoro that could be stopped."
        return 0
    endif
    let s:stoptime=localtime()
    let elapsed = s:stoptime - s:starttime
    " convert to minutes
    let elapsed = elapsed / 60
    if elapsed > 25
        elapsed = 25
    endif
    "echo "elapsed: ".elapsed
    let s:time += elapsed
    let s:pomodoro_active = 0
    " compose new line
    let line = s:PomodoroComposeLine()
    call setline(s:lineno, line)
    echo "Pomodoro stopped. ".elapsed." minutes have been added."
endfunction


function! PomodoroInfo()
    if s:pomodoro_active == 0
        echo "Pomodoro: inactive"
        return 0
    endif
    let stoptime=localtime()
    let elapsed = stoptime - s:starttime
    if elapsed >= 25*60
        echo "Pomodoro: '".s:title."' (expired) - Call PomodoroStop() now."
    else
        " countdown
        let elapsed = 25*60 - elapsed
        " convert to minutes
        let min = elapsed / 60
        let sec = elapsed % 60
        echo printf("Pomodoro: %s (%02u:%02u)", s:title, min, sec)
    endif
    " ugly hack to trigger another event
    call feedkeys("f\e")
endfunction

augroup Pomodoro
    autocmd!
    autocmd CursorHold * call PomodoroInfo()
    autocmd CursorMoved * call PomodoroInfo()
augroup end
