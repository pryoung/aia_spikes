
PRO aia_ingest_spikes, filelist

;+
; NAME:
;     AIA_INGEST_SPIKES
;
; PURPOSE:
;     Takes a set of AIA spikes files and ingests them into the
;     user's $AIA_SPIKES directory, organized by data and
;     wavelength channel. 
;
; CATEGORY:
;     SDO; AIA; file management.
;
; CALLING SEQUENCE:
;     AIA_INGEST_SPIKES, FileList
;
; INPUTS:
;     FileList:  List of files to be ingested.
;
; OUTPUTS:
;     Moves the files in FILELIST to the $AIA_SPIKES directory. If the
;     environment variable does not exist or the directory is not
;     found, then the routine exits.
;
; EXAMPLE:
;     First download the tar file from the JSOC, and unpack it into
;     the current directory:
;
;     IDL> sdoc_jsoc_check_status, request_id, /download
;
;     Then ingest the files:
;     IDL> list=file_search('*spikes*.fits')
;     IDL> aia_ingest_spikes,list
;
; MODIFICATION HISTORY:
;     Ver.1, 24-Mar-2021, Peter Young
;-


spike_dir=getenv('AIA_SPIKES')
IF spike_dir EQ '' THEN BEGIN
   print,'% AIA_INGEST_SPIKES: The $AIA_SPIKES variable is not defined. Returning...'
   return
ENDIF

chck=file_search(spike_dir,count=count)
IF count EQ 0 THEN BEGIN
   print,'% AIA_INGEST_SPIKES: $AIA_SPIKES not found. Perhaps data disk is not connected? Returning...'
   return
ENDIF

n=n_elements(filelist)
FOR i=0,n-1 DO BEGIN
   bits=str_sep(filelist[i],'.')
   wavestr=strpad(bits[3],4,fill='0')
  ;
   date=strmid(bits[2],0,10)
   dir=time2fid(date,/full_year,delim='/')
  ;
   outdir=concat_dir(spike_dir,dir)
   outdir=concat_dir(outdir,wavestr)
   chck=file_info(outdir)
   IF chck.exists EQ 0 THEN file_mkdir,outdir
   outfile=concat_dir(outdir,filelist[i])
   chck=file_info(outfile)
   IF chck.exists EQ 0 THEN file_move,filelist[i],outdir ELSE print,'File already exists ('+filelist[i]+'). Not copied.'
ENDFOR


END
