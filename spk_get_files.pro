

FUNCTION spk_get_files, date, wave, count=count

;+
; NAME:
;     SPK_GET_FILES
;
; PURPOSE:
;     Returns a list of AIA "spikes" files for the specified day and
;     wavelength. 
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     Result = SPK_GET_FILES( Date, Wave )
;
; INPUTS:
;     Date:   A string containing a date in a standard format. For
;             example, '2017-02-28'.
;     Wave:   An integer specifying an AIA filter. For example, 171 or
;             193. 
;
; OUTPUTS:
;     A string array containing the spikes filenames. If a problem
;     occurs, then a value of -1 is returned.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of files found.
;
; RESTRICTIONS:
;     Requires the environment variable $AIA_SPIKES to be set, and
;     files should be ingested with the routine AIA_INGEST_SPIKES.
;
; EXAMPLE:
;     IDL> list=spk_get_files('28-Feb-2017',193)
;
; MODIFICATION HISTORY:
;     Ver.1, 05-Apr-2021, Peter Young
;     Ver.2, 28-Apr-2021, Peter Young
;       Changed from recursive to standard file_search to avoid
;       picking up files in sub-directories.
;     Ver.3, 23-Aug-2021, Peter Young
;       Fixed errors in header; added extra information message; added
;       count= optional input.
;-


IF n_params() LT 2 THEN BEGIN
   print,'Use:  IDL> list = spk_get_files( date, wave [, count= ])'
   print,''
   print,'  (The spikes files should be in $AIA_SPIKES. See the routine aia_ingest_spikes.pro.)'
   return,-1
ENDIF 

spkdir=getenv('AIA_SPIKES')

tccsds=anytim2utc(date,/ccsds)

datedir=time2fid(tccsds,/full_year,delim='/')

filterdir=strpad(trim(wave),4,fill='0')

dir=concat_dir(spkdir,datedir)
dir=concat_dir(dir,filterdir)

chck=file_info(dir)
IF chck.exists EQ 0 THEN BEGIN
   print,'% SPK_GET_FILES: directory not found for this date and filter. Returning...'
   return,-1
ENDIF

list=file_search(concat_dir(dir,'*.spikes.fits'),count=count)

IF count EQ 0 THEN BEGIN
   print,'% SPK_GET_FILES: no files found for this date and filter. Returning...'
   return,-1
ENDIF

return,list

END

