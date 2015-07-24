;+
; NAME:
;    ADD_FLARE_NT
;PURPOSE: 
;   Add a simulated flare, scaled by arbitrary amount, to
;   an image cube of real NuSTAR data with a certain pixel size
;
;INPUTS:
;   Image cube, Frame #
;OPTIONAL:
;   scaling, pixel size, shift, energy range, livetime correction
;OUTPUTS:
;   Image cube with flare added to the desired frame

function add_flare_nt, imcube, frame, scale=scale, dwell=dwell,$
pix_size=pix_size, move=move, erange=erange, livetime=livetime

common flare_nt, flare_dir, flare_nt

if n_elements(flare_nt) eq 0 then begin
flare_dir = '/home/andrew/nusim/Solar/'
flare_nt = mrdfits(flare_dir+'flat_5-10keV_norm100.events.fits',1,fh)
endif

bkg_cts = total(imcube[*,*,frame])

a = where(flare_nt.module eq 1)    ;Events from 1 telescope (FPMA)
fa = flare_nt[a]
;b = where(flare2.module eq 2)    ;Events from FPMB
;fb = flare2[b]

;Select energy range
if n_elements(erange) ne 0 then begin
   emin = min(erange)
   emax = max(erange)
   kev = fa.e
   inrange = where((kev ge emin) and (kev le emax))
   fa = fa[inrange]
endif

SetDefaultValue, dwell, 100.
SetDefaultValue, scale, 0.01  ;reasonable starting point
SetDefaultValue, pix_size, 58  ;NuSTAR HPD
SetDefaultValue, livetime, 0.04  ;valid for obs2 NP pointing 

det1x = fa.det1x
det1y = fa.det1y

bin = 0.6 / 12.3 * pix_size ;correct binning for NuSIM image 
nf = hist_2d(det1x, det1y, bin1=bin, bin2=bin)
nf = nf * scale * (dwell/10.) * livetime
;livetime & temporal (dwell) scale factors
;Counts seen from flare in dwell # seconds, reduced by LT 
;eventually change so that LT is extracted from appropriate hk file

im0 = imcube[*,*,frame]

if n_elements(move) ne 0 then begin
   nf = shift(nf, move)
endif

;Add flare image to the imcube image
if ((size(nf))[1] eq (size(im0))[1]) && ((size(nf))[2] eq (size(im0))[2]) then begin
   im0 = im0 + nf
endif else begin
   sd = size(im0,/dimensions)
   sf = size(nf,/dimensions)
   if sd[0] gt sf[0] then begin
      ax = fltarr(sd[0] - sf[0], sf[1])
      nf = [nf,ax]
      sf = size(nf,/dimensions)
   endif
   if sd[1] gt sf[1] then begin
      ay = fltarr(sf[0], sd[1] - sf[1])
      nf = [[nf],[ay]]
   endif
   if sd[0] lt sf[0] then nf = nf[0:sd[0]-1,*]
   if sd[1] lt sf[1] then nf = nf[*, 0:sd[1]-1]

   im0 = im0 + nf
   
endelse

fimcube = imcube
;Normalize so that number of counts in frame stays constant 
fimcube[*,*,frame] = im0 * ( bkg_cts / total(im0) )

return, fimcube 



END
