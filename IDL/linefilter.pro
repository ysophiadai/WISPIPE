;+
; NAME:
;      linefilter
; PURPOSE:
;      find only the possibly high S/N lines for line-measurement 
;
; CALLING SEQUENCE:
;       linefinding, prefix
;
; INPUTS:
;       prefix - field number, the Par## in Par##line.dat file generated from detect_grism_lines_0p3.py
;
; OUTPUTS:
;       linelist2 - the list of selected objects only
;
;
;
; EXAMPLE:
;
; MODIFICATION HISTORY
;   Generated July 7, 2014 by Sophia Dai
; 
;-------------------------------------------------------------------------
pro linefilter,prefix

        readcol,prefix+'lines.dat',f='i,a,i,f,i,f,i',fd,grism,number2,wave,numpix,sigma,flag2
	openw,1,prefix+'linescheck.dat'
        id = [35, 45  ,  47,  1003,  77,    81,    121,   129,   141,   217,   309,   365,   389,   1008,  2039,  2159,  2221 , 2233]
        for i=0, n_elements(grism)-1 do begin
        for j=0, n_elements(id)-1 do begin
           if number2(i) eq id[j] then begin
              printf,1,fd(i),grism(i),number2(i),wave(i),numpix(i),sigma(i),flag2(i),format='(I3,A9,I6,F18.6,I6,F14.6,I10)'
              endif
        endfor
     endfor
	close,1

goto,eend
        readcol,prefix+'lines.dat',f='i,a,i,f,i,f,i',fd,grism,number2,wave,numpix,sigma,flag2
	openw,1,prefix+'lines2.dat'
        for i=0, n_elements(grism)-1 do begin
           if wave(i) gt 10800 and wave(i) lt 11500 and numpix(i) ge 3 and sigma(i) gt 5 then begin
              printf,1,fd(i),grism(i),number2(i),wave(i),numpix(i),sigma(i),flag2(i),format='(I3,A9,I6,F18.6,I6,F14.6,I10)'
              endif
        endfor
	close,1
eend:
end
