
PRO spk_respike_groups, date, wave, dir, metadata=metadata

;+
; NAME:
;     SPK_RESPIKE_GROUPS
;
; PURPOSE:
;     For the set of spike cutout directories, this routine takes each
;     FITS file and matches it to a spikes file. The cutout is then
;     respiked and saved in the 'respike' sub-directory.
;
; CATEGORY:
;     SDO; AIA; respike.
;
; CALLING SEQUENCE:
;     SPK_RESPIKE_GROUPS, Date, Wave, Dir
;
; INPUTS:
;     Date:   A string containing the date in a standard format. For
;             example, '28-Feb-2017' or '2017-02-28'.
;     Wave:   An integer specifying an AIA EUV filter. For example,
;             171 or 193.
;     Dir:    The top directory containing the cutout
;             sub-directories. 
;
; OPTIONAL INPUTS:
;     Metadata:  The structure containing the spike metadata (obtained
;                with spk_get_metadata). If you give this as input,
;                make sure it was derived using the same DATE and WAVE
;                values used as input to this routine.
;
; OUTPUTS:
;     For each of the cutout sub-directories the routine creates a new
;     sub-diretory called 'respike' that contains the re-spiked
;     cutouts. 
;
; EXAMPLE:
;     IDL> spk_respike_groups, '28-Feb-2017', 171, '~/my_cutouts'
;
; MODIFICATION HISTORY:
;     Ver.1, 06-Apr-2021, Peter Young
;     Ver.2, 10-Sep-2021, Peter Young
;       Caught case where there's a mismatch between metdata
;       and the spikes file list.
;-


list=file_search(concat_dir(dir,'*'),/test_dir,count=n)

spikelist=spk_get_files(date,wave,count=count)

IF n_elements(metadata) EQ 0 THEN metadata=spk_get_metadata(date,wave)

spk_tai=anytim2tai(metadata.t_obs)

;
; This is a kluge for the case where the first entry in metadata
; actually belongs to the previous day (this happened for 211 in one
; case). 
;
read_sdo,spikelist[0],index,/use_shared,/silent
t_obs_tai=anytim2tai(index.t_obs)
IF t_obs_tai-spk_tai[0] GE 5.0 THEN BEGIN
   print,'% SPK_RESPIKE_GROUPS: mismatch between metadata and spikelist. Adjusting arrays.'
   metadata=metadata[1:*]
   spikelist=spikelist[0:count-2]
ENDIF 


;
; Go through each of the cutout sub-directories in DIR and respike
; each of the cutouts.
;
FOR i=0,n-1 DO BEGIN
   print,'Processing '+trim(i+1)+' of '+trim(n)+'...'
  ;
  ; Clean out the respike directory if it already exists.
  ;
   respikedir=concat_dir(list[i],'respike')
   chck=file_info(respikedir)
   IF chck.exists EQ 1 THEN file_delete,respikedir,/recursive
  ;
   filelist=file_search(list[i],'*.fits',count=m)
  ;
   read_sdo,filelist[0],index,/use_shared,/silent
   t0_tai=anytim2tai(index.t_obs)
  ;
   read_sdo,filelist[-1],index,/use_shared,/silent
   t1_tai=anytim2tai(index.t_obs)
  ;
  ; The t_obs values are slightly different in the spikes and data
  ; files, so I have to pad the check range by 3 seconds to make sure
  ; I pick up the correct number of files.
  ;
   k=where(spk_tai GE min(t0_tai)-3 AND spk_tai LE max(t1_tai)+3,nk)
   IF nk NE m THEN print,'***WARNING: mismatch in cutout and spikes files***',m,nk
   spikefiles=spikelist[k]
  ;
   aia_cutout_respike,filelist,spikelist=spikefiles
ENDFOR

END
