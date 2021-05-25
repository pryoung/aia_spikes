

FUNCTION spk_process_sequence, filelist, indir=indir


;+
; NAME:
;      SPK_PROCESS_SEQUENCE()
;
; PURPOSE:
;      Takes a sequence of spike files and identifies spikes  that are
;      present at the same location in 3 consecutive frames.
;
;      I automatically filter out events that are outside of R=1000".
;
; CATEGORY:
;      SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;      Result = SPK_PROCESS_SEQUENCE( FileList )
;
; INPUTS:
;      Filelist:   A string array of filenames.
;
; OPTIONAL INPUTS:
;      Indir:      A directory containing a list of spikes files.
;	
; OUTPUTS:
;      A structure with the following tags:
;         I               INT           2402
;         J               INT           1000
;         R               FLOAT           662.132
;         SPIKEFILE       STRING    'aia.lev1_euv_12s.2016-02-15T000443Z.193.spik'...
;         X               FLOAT           216.197
;         Y               FLOAT          -625.842
;         TIME_RANGE      STRING    Array[2]
;         REQUESTID       Empty string.
;         WAVE            AIA wavelength.
;      (I,J) give the pixel location in the level-1 image, R gives the
;      radial location (relative to sun center in arcsec). (X,Y) give
;      the location in heliocentric coordinates. TIME_RANGE gives the
;      time range in which the event occurs.
;
; CALLS:
;      READ_SDO
;
; EXAMPLE:
;      IDL> list=file_search('*spikes.fits')
;      IDL> output=spk_process_sequence(list)
;
;      IDL> output=spk_process_sequence(indir='.')
;
; MODIFICATION HISTORY:
;      Ver.1, 18-Mar-2016, Peter Young
;      Ver.2, 6-Apr-2016, Peter Young
;         added 'spikes' and 'despikes' to the output.
;      Ver.3, 31-Mar-2021, Peter Young
;         tidied up header.
;      Ver.4, 07-Apr-2021, Peter Young
;         added requestid and wave to output structure. 
;-



IF n_elements(filelist) EQ 0 THEN BEGIN
  filelist=file_search(indir,'*.spikes.fits',count=n)
ENDIF ELSE BEGIN
  n=n_elements(filelist)
ENDELSE 


str={i: -1, j:-1, r: 0., spikefile: '', $
     x: 0., y: 0., time_range: strarr(2), $
     spikes: fltarr(3), despikes: fltarr(3), $
     requestid: '', wave: 0}
output=0

read_sdo,filelist[0],index0,data0,/use_shared_lib,/silent
str.wave=index0.wavelnth
read_sdo,filelist[1],index1,data1,/use_shared_lib,/silent
FOR i=1,n-2 DO BEGIN
  read_sdo,filelist[i+1],index2,data2,/use_shared_lib,/silent
  s=size(data1,/dim)
  nn=s[0]
  FOR j=0,nn-1 DO BEGIN
    k=where(data1[j,0] EQ data0[*,0],nk)
    IF nk NE 0 THEN BEGIN
      k2=where(data1[j,0] EQ data2[*,0],nk2)
      IF nk2 NE 0 THEN BEGIN 
        ij=get_ij(data1[j,0],4096)
        str.i=ij[0]
        str.j=ij[1]
        str.x=(ij[0]-index1.crpix1)*index1.cdelt1
        str.y=(ij[1]-index1.crpix2)*index1.cdelt2
        str.r=sqrt( str.x^2 + str.y^2 )
        str.spikes=[data0[k[0],1],data1[j,1],data2[k2[0],1]]
        str.despikes=[data0[k[0],2],data1[j,2],data2[k2[0],2]]
        str.time_range=[index0.t_obs,index2.t_obs]
        str.spikefile=filelist[i]
        IF n_tags(output) EQ 0 THEN output=str ELSE output=[output,str]
      ENDIF 
    ENDIF     
  ENDFOR
  index0=temporary(index1)
  data0=temporary(data1)
  index1=temporary(index2)
  data1=temporary(data2)
ENDFOR 


;
; Get rid of events above R=1000 as these seem to be hot pixels. 
;
k=where(output.r LE 1000.,nk)
IF nk GT 0 THEN output=output[k] ELSE output=-1

return,output

END

