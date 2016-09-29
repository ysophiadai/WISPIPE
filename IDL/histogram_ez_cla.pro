; This EZ histogram function will make histogramming easier.  
; ES 2000-02-27.  Features:
; - if your minimum data point is 4.26, histogram_ez will take the lowest
;   bin to be from 4.0 to 5.0 (with a binsize of 1), or 3.0 to 6.0 (with 
;   a binsize of 3) or 0.0 to 5.0 (with a binsize of 5).  In other words,
;   it's pretty damn smart.  [The IDL built-in histogram routine would
;   go from 4.26 to 5.26.]
; - it graphs it correctly and you don't have to worry about the x-axis
;   lining up, because histogram_ez worries for you.
; - if behavior of the histogram function didn't go to zero at the endpoints,
;   the old routine would screw up the graph.

; The min=starthere is to force the histogram plot to have
; its left edge coincide with a nice number.

; by Edwin Sirko
; 2002-08-07. Added xaxis and yaxis to pass back to calling routine.
; 2003-11-21: found possible bug: starthere is wrong for negative values.

; 2014-01-29 Changes:
; added /nan  to avoid wrongly read min values in NAN
; everything to double format
; Comments added by Sophia Dai
; 2014.07

function histogram_ez_cla,array,binsize=binsize,$
	xaxis=xaxis,yaxis=visual_density,silent=silent,_extra=extra


if n_elements(binsize) eq 0 then binsize=1.
starthere = double(min(array,/nan)/binsize) * binsize
binsize = double(binsize)
;give density arrays based on the array input (sky magnitude)
density = histogram(array,binsize=binsize,min=starthere,/nan,$
	omax=omax,omin=omin)
; Find how many elements in density
number_unique = n_elements(density)

; Need to pad with zeros at either end so that the histogram doesn't
; get stranded in midair
visual_density = fltarr(number_unique+2)
visual_density(1:number_unique) = density
; the binsize scales it horizontally.
; the omin makes sure it lines up correctly
xaxis = (findgen(number_unique+2)-.5)*binsize + omin

if not keyword_set(silent) then $
plot,xaxis,visual_density,psym=10,xrange=[omin,omax],_extra=extra
out=dblarr(2,n_elements(xaxis))
out[0,*]=xaxis
out[1,*]=visual_density
return,out
end
