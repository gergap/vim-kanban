" kanban.vim - Extends VimWiki with pomodoro items
" Maintainer:   Gerhard Gappmeier
" Version:      1.0

if exists("g:loaded_kanban")
    finish
endif
"let g:loaded_kanban = 1
let s:pomodoro_active = 0
let s:pomodoro_break_active = 0
let s:pomodoro_break_time = 5
let s:todolist=0
let s:ticketsize=0
let s:title=''
let s:startdate=0
let s:enddate=0
let s:time=0
let s:starttime=0

" A pomodoro item is an extension to a VimWiki todo item.
" and loooks like this.
" Example: * [o] [M] test bla (19/08/15,20/08/15,10)
"             ^   ^  ^^^^^^^^  ^^^^^^^^ ^^^^^^^^ ^^
"             |   |  |         |        |        |
"             |   |  |         |        |        +-- Working minutes
"             |   |  |         |        +-- End Date
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
    let regex = '\V\( \** [\[ .oOX]]\) [\(\[ SML]\)] \(\[A-Za-z0-9_ :.,]\+\) ('.dateregex.'\?,'.dateregex.'\?,\(\d\*\))'
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

" This starts a new pomodoro if there is not already an active one.
" This will cancel any break and avoids explicit stopping of breaks.
function! PomodoroStart()
    if s:pomodoro_active
        "echoerr "There is already an active pomodoro: '".s:title."'"
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
        let s:pomodoro_break_active = 0
        "echo "Pomodoro started."
    else
        "echoerr "No valid pomodoro found on this line."
    endif
endfunction

" Stops an active pomodoro or break.
" If a pomodoro was stopped this will upate the work time.
function! PomodoroStop()
    if s:pomodoro_break_active
        let s:pomodoro_break_active = 0
        return
    endif
    if s:pomodoro_active == 0
        "echoerr "No active pomodoro that could be stopped."
        return
    endif
    let s:stoptime=localtime()
    let elapsed = s:stoptime - s:starttime
    " convert to minutes
    let elapsed = elapsed / 60
    if elapsed > 25
        let elapsed = 25
    endif
    "echo "elapsed: ".elapsed
    let s:time += elapsed
    let s:pomodoro_active = 0
    " compose new line
    let line = s:PomodoroComposeLine()
    call setline(s:lineno, line)
    "echo "Pomodoro stopped. ".elapsed." minutes have been added."
endfunction

" This finishes a pomodoro.
" This works like PomodorStop() but will in addition also update
" the enddate and mark this pomodoro as done by checking the checkbox
" of the VimWiki todo item.
function! PomodoroFinish()
    if s:pomodoro_active == 0
        "echoerr "No active pomodoro that could be stopped."
        return 0
    endif
    let s:stoptime=localtime()
    let elapsed = s:stoptime - s:starttime
    " convert to minutes
    let elapsed = elapsed / 60
    if elapsed > 25
        let elapsed = 25
    endif
    "echo "elapsed: ".elapsed
    let s:time += elapsed
    let s:enddate = strftime("%d/%m/%y")
    echom s:todolist
    let s:todolist = substitute(s:todolist, '\[ \]', '[X]', '')
    echom s:todolist
    let s:pomodoro_active = 0
    " compose new line
    let line = s:PomodoroComposeLine()
    call setline(s:lineno, line)
    "echo "Pomodoro stopped. ".elapsed." minutes have been added."
    "call VimwikiToggleListItem()
endfunction

" This starts a short break countdown.
function! PomodoroBreak()
    let s:title = "Short break"
    let s:pomodoro_break_time = 5
    let s:starttime=localtime()
    let s:pomodoro_break_active = 1
endfunction

" This starts a long break countdown.
function! PomodoroLongBreak()
    let s:title = "Short break"
    let s:pomodoro_break_time = 15
    let s:starttime=localtime()
    let s:pomodoro_break_active = 1
endfunction

" This creates a pomodoro item.
function! PomodoroCreate(...)
    let title = "Enter title"
    let size = "S"
    if a:0 > 0
        let title = a:1
    endif
    if a:0 > 1
        let size = a:2
    endif
    let line='* [ ] ['.size.'] '.title.' (,,)'
    call append('.', line)
endfunction

" This functions returns information about active pomdoros or breaks.
" This is used by the vim-airline plugin to display the pomodoro status.
function! g:PomodoroInfo()
    let info = ''
    if s:pomodoro_active == 0 && s:pomodoro_break_active == 0
        return "Pomodoro: inactive"
    endif
    let stoptime=localtime()
    let elapsed = stoptime - s:starttime
    if s:pomodoro_active
        " return pomodoro info
        if elapsed >= 25*60
            let info = "Pomodoro: '".s:title."' (expired) - Call PomodoroStop() now."
        else
            " countdown
            let elapsed = 25*60 - elapsed
            " convert to minutes
            let min = elapsed / 60
            let sec = elapsed % 60
            let info = printf("Pomodoro: %s (%02u:%02u)", s:title, min, sec)
        endif
    else
        " return pomodoro break info
        if elapsed >= s:pomodoro_break_time*60
            let info "Pomodoro: Break is over. Time for another pomodoro!"
        else
            " countdown
            let elapsed = s:pomodoro_break_time*60 - elapsed
            " convert to minutes
            let min = elapsed / 60
            let sec = elapsed % 60
            let info = printf("Pomodoro: %s (%02u:%02u)", s:title, min, sec)
        endif
    endif
    return info
endfunction

" Simple function for toggling pomodoro running/stopped states.
" This can be mapped to any key to simplify starting and stopping of
" pomodoros.
function! PomodoroToggle()
    if s:pomodoro_active
        call PomodoroStop()
    else
        call PomodoroStart()
    endif
endfunction

nmap <leader><space> :call PomodoroToggle()<cr>

"augroup Pomodoro
"    autocmd!
"    autocmd CursorHold * call PomodoroInfo()
"    autocmd CursorMoved * call PomodoroInfo()
"augroup end
