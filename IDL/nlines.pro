; Name:
;       nlines
; Purpose:
;       Return the number of lines in a file
; Usage:
;       nl = nlines(file)
; Inputs:
;       file = file to scan
; Optional Inputs or Keywords:
;       help = flag to print header
; Outputs:
;       nl = number of lines in the file.
; Common blocks:
;       none
; Procedure:
;       Assume ASCII data and read through file.
; Modification history:
;       write, 24 Feb 92, F.K.Knight
;-
function nlines,file,help=help
;
;       =====>> HELP
;
on_error,2
if keyword_set(help) then begin & doc_library,'nlines' & return,0 & endif
;
;       =====>> LOOP THROUGH FILE COUNTING LINES
;
tmp = ' '
nl = 0
on_ioerror,NOASCII
;if n_elements(file) eq 0 then file = pickfile()
openr,lun,file,/get_lun
while not eof(lun) do begin
  readf,lun,tmp
  nl = nl + 1
  endwhile
close,lun
free_lun,lun
NOASCII:
return,nl
end
; of
;0:return,0                              ; UNDEFINED
;1:return,nelements                      ; BYTE
;2:return,nelements*2                    ; INT
;3:return,nelements*4                    ; LONG
;4:return,nelements*4                    ; FLOAT
;5:return,nelements*8                    ; DOUBLE
;6:return,nelements*8                    ; COMPLEX
