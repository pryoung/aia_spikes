
PRO spk_respike_cutouts, cutout_files, $
                         spike_dir=spike_dir, outfiles=outfiles


;+
; NAME:
;      SPK_RESPIKE_CUTOUTS
;
; PURPOSE:
;      Takes a list of cutout files and uses the spike files that the
;      user has already downloaded to respike the cutouts.
;
; CATEGORY:
;      SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;      SPK_RESPIKE_CUTOUTS, Cutout_Files
;
; INPUTS:
;      Cutout_Files:  A string array containing the names of the
;                     cutout files to be respiked.
;
; OPTIONAL INPUTS:
;      Spike_Dir:  The directory containing the spikes files. This
;                  directory can contain the complete set of spikes
;                  files for the day (the routine will automatically
;                  match the spikes files to the cutouts).
;	
; OUTPUTS:
;      Creates a subdirectory 'respike' in the directory where the
;      CUTOUT_FILES are stored, and the respiked FITS files are stored
;      here. 
;
; OPTIONAL OUTPUTS:
;      Outfiles: This is the list of spike filenames that match the
;                input CUTOUT_FILES.
;
; CALLS:
;      AIA_CUTOUT_RESPIKE, SPK_GET_FILES
;
; EXAMPLE:
;      IDL> list=file_search('*.fits')
;      IDL> spk_request_cutouts, list, spike_dir='~/spikes'
;
; MODIFICATION HISTORY:
;      Ver.1, 23-Aug-2021, Peter Young
;        Added additional checks; now tries to find the spikes
;        directory from the cutout filename (so spike_dir not
;        necessary); added /silent keywords to AIA routines.
;-

IF n_params() LT 1 THEN BEGIN
   print,'Use:  IDL> spk_respike_cutouts, cutout_files [ spike_dir=, outfiles= ]'
   return
ENDIF 

;
; Extract the times of the files from the filenames themselves
; (so don't have to use read_sdo).
;
cfiles=file_basename(cutout_files)
tc=strmid(cfiles,17,17)
wave=strmid(cfiles,36,3)
tc_utc=strmid(tc,0,13)+':'+strmid(tc,13,2)+':'+strmid(tc,15,2)
tc_tai=anytim2tai(tc_utc)
nc=n_elements(cfiles)

;
; t0 and t1 are the times of the first and last frames of the cutout sequence.
;
t0_tai=min(tc_tai)
t1_tai=max(tc_tai)

;
; Here I get the complete set of spike files for the day. If spike_dir
; is not specified, then I get the spike list by using the date and
; wavelength information in the name of the first cutout file.
;
IF n_elements(spike_dir) EQ 0 THEN BEGIN
   date=anytim2utc(/ccsds,tc_utc[0],/date)
   print,'% SPK_RESPIKE_CUTOUTS: looking for spike files for '+trim(date)+' and wavelength '+trim(wave[0])+'...'
   spike_list=spk_get_files(date,wave[0],count=count)
   print,'% SPK_RESPIKE_CUTOUTS: found '+trim(count)+' spike files.'
ENDIF ELSE BEGIN
   spike_list=file_search(spike_dir,'*.spikes.fits',count=count)
ENDELSE
;
IF count EQ 0 THEN BEGIN
   print,'% SPK_RESPIKE_CUTOUTS: no spike files match the cutout sequence. Returning...'
   return
ENDIF 


;
; Process the spike filenames to extract the times of each file.
;
sfiles=file_basename(spike_list)
ts=strmid(sfiles,17,17)
ts_utc=strmid(ts,0,13)+':'+strmid(ts,13,2)+':'+strmid(ts,15,2)
ts_tai=anytim2tai(ts_utc)

;
; Reduce the spike file list by checking against time range of the
; cutout list. This is to avoid reading the full list of spike files. 
;
k=where(ts_tai GE t0_tai-12. AND ts_tai LE t1_tai+12.,nk)
IF nk EQ 0 THEN BEGIN
   print,'% SPK_RESPIKE_CUTOUTS: no spike files match the cutout sequence. Returning...'
   return
ENDIF 
spike_list=spike_list[k]

;
; Read the headers of all the spikes files (this will take a while).
; 
read_sdo,spike_list,sindex,/use_shared,/silent

;
; Now read the cutout files and match them to the spikes files.
;
outfiles=strarr(nc)
FOR i=0,nc-1 DO BEGIN
  read_sdo,cutout_files[i],cindex,/use_shared,/silent
  k=where(cindex.t_obs EQ sindex.t_obs,nk)
  IF nk NE 0 THEN outfiles[i]=spike_list[k]
ENDFOR 

k=where(outfiles EQ '',nk)
IF nk NE 0 THEN print,'% SPK_RESPIKE_CUTOUTS: '+trim(nk)+' cutout files do not have matching spike files.'

aia_cutout_respike,cutout_files,spikelist=outfiles,/silent


END
