
PRO spk_download_cutouts, jsoc, outdir=outdir

;+
; NAME:
;     SPK_DOWNLOAD_CUTOUTS
;
; PURPOSE:
;     Downloads
;
; CATEGORY:
;     SDO; AIA; JSOC; spikes.
;
; CALLING SEQUENCE:
;	Spk_Download_Cutouts, Jsoc
;
; INPUTS:
;     Jsoc:   The structure output by SPK_REQUEST_CUTOUTS. Contains
;             the JSOC request IDS required to retrieve the
;             downloads. 
;
; OPTIONAL INPUTS:
;     Outdir:  The directory to download the cutout images. Note that
;              sub-directories for each requestid will be created
;              within OUTDIR and the images go in these. If not
;              specified, then the current working directory is used.
;	
; OUTPUTS:
;     For the all the requestids in JSOC, this routine downloads the
;     cutout fits files from the JSOC and puts them in
;     OUTDIR/requestid.
;
; PROGRAMMING NOTES:
;     For each request ID, the routine queries the JSOC to see if the
;     files are ready. If not, then the routine waits 10 seconds and
;     tries again. This will repeat for a total of 2000 seconds before
;     giving up.
;
; EXAMPLE:
;     IDL> spk_download_cutouts,jsoc,outdir='~/my_spikes'
;
; MODIFICATION HISTORY:
;     Ver.1, 26-Apr-2021, Peter Young
;-


IF n_params() LT 1 THEN BEGIN
   print,'Use:  IDL> spk_download_cutouts, jsoc [, outdir=]'
   print,''
   print,'  jsoc - the output structure from spk_request_cutouts.'
   return 
ENDIF 

n=n_elements(jsoc)
info=bytarr(n)

IF n_elements(outdir) NE 0 THEN BEGIN 
   chck=file_info(outdir)
   IF chck.exists EQ 0 THEN file_mkdir,outdir
ENDIF ELSE BEGIN
   outdir='.'
ENDELSE 

FOR i=0,n-1 DO BEGIN
   requestid=jsoc[i].requestid
   swtch=0
   IF trim(requestid) NE 'none' THEN BEGIN
      FOR j=0,199 DO BEGIN 
         sdo_jsoc_check_status,requestid, status=status
         IF status EQ 1 THEN BEGIN
            swtch=1
            BREAK
         ENDIF 
         wait,10.
      ENDFOR
      IF swtch EQ 1 THEN BEGIN
         dir=concat_dir(outdir,requestid)
         sdo_jsoc_check_status,requestid,/download,outdir=dir
      ENDIF 
   ENDIF 
ENDFOR

END
