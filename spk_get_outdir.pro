
FUNCTION spk_get_outdir, date, wave, my_data_dir=my_data_dir

;+
; NAME:
;     SPK_GET_OUTDIR()
;
; PURPOSE:
;     Creates the output directory for the spikes cutouts files. 
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     Result = SPK_GET_OUTDIR( Date, Wave )
;
; INPUTS:
;     Date:   The date in a standard SSW format. For example,
;             '28-Feb-2017'.
;     Wave:   An integer specifying the AIA channel. For example, 193
;             or 171.
;
; OPTIONAL INPUTS:
;     My_Data_Dir:  The top-level directory in which to put the
;                   files. If not specified, then the current working
;                   directory is used. All files will go into the
;                   sub-directory 'aia_spikes'. 
;
; OUTPUTS:
;     A string giving the output directory. The routine will create
;     this directory if it does not already exist.
;
; EXAMPLE:
;     IDL> outdir=spk_get_outdir('28-feb-2017',193,my_data_dir='/Volumes/my_data')
;
; MODIFICATION HISTORY:
;     Ver.1, 08-Sep-2021, Peter Young
;-

IF n_elements(my_data_dir) EQ 0 THEN my_data_dir='.'

wavestr=strpad(trim(wave),4,fill='0')
dir=time2fid(date,/full_year,delim='/')
;
outdir=concat_dir(my_data_dir,'aia_spikes')
outdir=concat_dir(outdir,dir)
outdir=concat_dir(outdir,wavestr)
chck=file_info(outdir)
IF chck.exists EQ 0 THEN file_mkdir,outdir

return,outdir

END
