
FUNCTION spk_get_time_range, date, wave, time_range=time_range, metadata=metadata

;+
; NAME:
;     SPK_GET_TIME_RANGE
;
; PURPOSE:
;     Allows you extract a subset of the complete spike file list
;     based on a time range. To save reading in the spikes files, the
;     routine extracts metadata from the JSOC.
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     Result = SPK_GET_TIME_RANGE( Date, Wave )
;
; INPUTS:
;     Date:   A string containing the date in a standard format. For
;             example, '28-Feb-2017' or '2017-02-28'.
;     Wave:   An integer specifying an AIA EUV filter. For example,
;             171 or 193.
;
; OPTIONAL INPUTS:
;     Time_Range:  A 2-element string array giving a range of
;                  times. For example, ['03:00','06:00']. Note that
;                  you do *not* specify the date!
;     Metadata:  The structure returned by SPK_GET_METADATA. This can
;                be used as an input to speed up the routine.
;	
; OUTPUTS:
;     A string array containing the list of files that satisfy the
;     TIME_RANGE specification. If a problem is found then an empty
;     string is returned.
;
; OPTIONAL OUTPUTS:
;     Metadata:  The structure returned by SPK_GET_METADATA.
;
; EXAMPLE:
;     IDL> filelist=spk_get_time_range('27-feb-2017',171,time_range=['03:00','06:00']
;
; MODIFICATION HISTORY:
;     Ver.1, 06-Apr-2021, Peter Young
;-

IF n_elements(time_range) EQ 2 THEN BEGIN
   t0=date+' '+time_range[0]
   t1=date+' '+time_range[1]
  ;
   t0_tai=anytim2tai(t0)
   t1_tai=anytim2tai(t1)
ENDIF ELSE BEGIN
   print,"% SPK_GET_TIME_RANGE: the input TIME_RANGE must be specified in the form ['03:00','06:00']. Returning..."
   return,''
ENDELSE 

filelist=spk_get_files(date,wave)

IF n_elements(metadata) EQ 0 THEN metadata=spk_get_metadata(date,wave)
tobs_tai=anytim2tai(metadata.t_obs)
k=where(tobs_tai GE t0_tai AND tobs_tai LE t1_tai,nk)

IF nk NE 0 THEN BEGIN
   filelist=filelist[k]
   return,filelist
ENDIF ELSE BEGIN
   return,''
ENDELSE 


END
