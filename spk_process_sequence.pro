

FUNCTION spk_process_sequence, filelist, indir=indir, info=info


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
;         REQUESTID       Empty string (filled by spk_group_spikes).
;         WAVE            AIA wavelength.
;         DUR             Set to zero (filled by spk_group_spikes).
;         SPK_IND_STR     Empty string (filled by spk_group_spikes).
;
;      (I,J) give the pixel location in the level-1 image, R gives the
;      radial location (relative to sun center in arcsec). (X,Y) give
;      the location in heliocentric coordinates. TIME_RANGE gives the
;      time range in which the event occurs.
;
; OPTIONAL OUTPUTS:
;      Info:  An IDL stucture with the following tags:
;             .n_frames  No. of image frames.
;             .n_3spikes  Total no. of 3-spikes.
;             .n_hot     No. of hot pixels.
;             .n_offlimb  No. of offlimb pixes (after hot pixel
;                         removal).
;             .hot_thresh The threshold for defining hot pixels.
;             .offlimb_thresh Threshold for defining off-limb
;                             (arcsec).
;             .time_taken  Time taken by routine (minutes).
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
;      Ver.5, 21-Jun-2021, Peter Young
;         added 'dur' and 'spk_ind_str' tags to output.
;      Ver.6, 31-Aug-2021, Peter Young
;         now flag hot pixels before processing the 3-spikes as this
;         results in a big time saving; added optional output INFO.
;-


t0=systime(1)

IF n_elements(filelist) EQ 0 THEN BEGIN
  filelist=file_search(indir,'*.spikes.fits',count=n)
ENDIF ELSE BEGIN
  n=n_elements(filelist)
ENDELSE 

n_frames=n

str={ij: 0l, i: -1, j:-1, r: 0., spikefile: '', $
     x: 0., y: 0., time_range: strarr(2), $
     spikes: fltarr(3), despikes: fltarr(3), $
     requestid: '', wave: 0, dur: 0., spk_ind_str: ''}
output=0

;
; The following checks for hot pixels. The array "count" records the
; number of spikes occurring in each spatial pixel.
; If the number is > 10% of the number of frames then I consider the
; pixel to be a hot pixel.
; Hot pixels get ignored in the next part of the code. This results in
; a big time saving.
;
count=intarr(4096,4096)
;
FOR i=0,n-1 DO BEGIN
   read_sdo,filelist[i],index,data,/use_shared,/silent
   count[data[*,0]]=count[data[*,0]]+1
ENDFOR
hot_thresh=fix(float(n)/10.)
hot_pix=where(count GE hot_thresh,n_hot)
junk=temporary(count)


read_sdo,filelist[0],index0,data0,/use_shared_lib,/silent
str.wave=index0.wavelnth
read_sdo,filelist[1],index1,data1,/use_shared_lib,/silent
FOR i=1,n-2 DO BEGIN
  read_sdo,filelist[i+1],index2,data2,/use_shared_lib,/silent
  s=size(data1,/dim)
  nn=s[0]
  FOR j=0,nn-1 DO BEGIN
    ;
    ; If a hot pixel, then immediately skip
    ;
     chck=where(data1[j,0] EQ hot_pix,nchck)
     IF nchck GT 0 THEN CONTINUE
    ;
    k=where(data1[j,0] EQ data0[*,0],nk)
    IF nk NE 0 THEN BEGIN
      k2=where(data1[j,0] EQ data2[*,0],nk2)
      IF nk2 NE 0 THEN BEGIN
         str.ij=data1[j,0]
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
         count[str.ij]=count[str.ij]+1
      ENDIF 
    ENDIF     
  ENDFOR
  index0=temporary(index1)
  data0=temporary(data1)
  index1=temporary(index2)
  data1=temporary(data2)
ENDFOR 



;
; Get rid of events above R=1000 as these are likely spurious. (Note:
; most of these will be flagged by the hot pixel code.)
;
offlimb_thresh=1000.
k=where(output.r GT offlimb_thresh,nk)
IF nk GT 0 THEN BEGIN
   ij=output[k].ij
   b=ij[uniq(ij,sort(ij))]
   n_offlimb=n_elements(b)
ENDIF ELSE BEGIN
   n_offlimb=0
ENDELSE 
;
k=where(output.r LE offlimb_thresh,nk)
IF nk GT 0 THEN BEGIN
   output=output[k]
   n_3spikes=n_elements(output)
ENDIF ELSE BEGIN
   output=-1
   n_3spikes=0
ENDELSE 
   
t1=systime(1)
time_taken=(t1-t0)/60.   ; minutes

;
; n_hot  This is the number of hot pixels.
; n_offlimb  This is the number of unique of off-limb pixels. 
;
info={ n_frames: n_frames, $
       n_3spikes: n_3spikes, $
       n_hot: n_hot, $
       n_offlimb: n_offlimb, $
       hot_thresh: hot_thresh, $
       offlimb_thresh: offlimb_thresh, $
       time_taken: time_taken }


return,output

END

