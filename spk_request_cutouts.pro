
PRO spk_request_cutouts, input, wavel, email ,output=output, cadence=cadence, $
                         xsize=xsize, ysize=ysize, twindow=twindow


;+
; NAME:
;      SPK_REQUEST_CUTOUTS
;
; PURPOSE:
;      Using the output from SPK_GROUP_SPIKES, this routine sends
;      cutout requests to the JSOC to retrieve movie data for each
;      event.
;
; CATEGORY:
;      SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;      SPK_REQUEST_CUTOUTS, Input, Wavel
;
; INPUTS:
;      Input:   A structure produced by spk_group_spikes.pro. Note
;               that the REQUESTID tag gets filled by this routine.
;      Wavel:   An AIA wavelength (angstroms). Can be array.
;      Email:   This should be your registered username at JSOC.
;
; OPTIONAL INPUTS:
;      Cadence:  A string specifying cadence. E.g., '5m' or '1h'. The
;                default is '12s'.
;      Xsize:    Size of cutout in X-direction (arcsec). Default is 50.
;      Ysize:    Size of cutout in Y-direction (arcsec). Default is
;      50.
;      Twindow:  Defines the duration of the sequence to be
;                downloaded. If the spikes are present for time the
;                time interval [t0,t1], then the downloaded sequence
;                will extend from t0-twindow to t1+twindow, where
;                twindow is given in minutes. The default is twindow=5
;                minutes. 
;	
; OUTPUTS:
;      Sends queries to the JSOC. You should receive emails as each
;      request is processed.
;
;      The requestid tag of INPUT is modified to contain the JSOC
;      request ID. 
;
; OPTIONAL OUTPUTS:
;      Output:  A structure of same size as INPUT. Contains the tags:
;               .requestid    - needed to download data.
;               .requestsize
;               .datetimestart
;               .datetimeend
;
; CALLS:
;      SDO_ORDERJSOC (Rob Rutten)
;
; EXAMPLE:
;      IDL> group=spk_group_spikes(spikes)
;      IDL> spk_request_cutouts, group, 171, 'me@email.com', output=output
;
; MODIFICATION HISTORY:
;      Ver.1, 4-Apr-2016, Peter Young
;      Ver.2, 19-Feb-2020, Peter Young
;         Updated call to sdo_orderjsoc.
;      Ver.3, 26-Mar-2021, Peter Young
;         Changed the format for datetimestart (input to
;         sdo_orderjsoc).
;      Ver.4, 31-Mar-2021, Peter Young
;         Updated header; added EMAIL, XSIZE and YSIZE inputs.
;      Ver.5, 06-Apr-2021, Peter Young
;         Fixed bug in xsize and ysize implementation.
;      Ver.6, 30-Aug-2021, Peter Young
;         Added twindow= optional input.
;      Ver.7, 07-Sep-2021, Peter Young
;         If R>940 then set notrack=1, to prevent problems with cutout
;         tracking if close or above limb.
;-



IF n_params() LT 3 THEN BEGIN
  print,'Use:  spk_request_cutouts, input, wavel, email [, output=, cadence=, xsize=, ysize=]'
  print,''
  print,'   email - your registered email address with JSOC.'
  return 
ENDIF 

IF n_elements(xsize) EQ 0 THEN xsize=50
IF n_elements(ysize) EQ 0 THEN ysize=50

IF n_elements(twindow) EQ 0 THEN twindow=5.0

nw=n_elements(wavel)
IF nw NE 0 THEN BEGIN
  wavs=strarr(nw)
  FOR i=0,nw-1 DO wavs[i]=trim(wavel[i])
ENDIF 

IF n_elements(cadence) EQ 0 THEN cadence='12s'

n=n_elements(input)

junk=temporary(output)

str={ requestid: '', $
      tstart: '', $
      tend: '', $
      requestsize: '' }
output=replicate(str,n)


FOR i=0,n-1 DO BEGIN
   IF input.r GE 940 THEN notrack=1 ELSE notrack=0
   trange_tai=anytim2tai(input[i].time_range)
   trange_tai=trange_tai/60. + [-twindow,twindow]
   duration=trange_tai[1]-trange_tai[0]
   t_ex=anytim2utc(/ex,trange_tai[0]*60.)
   datetimestart=trim(t_ex.year)+'.'+ $
                 strpad(trim(t_ex.month),2,fill='0')+'.'+ $
                 strpad(trim(t_ex.day),2,fill='0')+'_'+ $
                 strpad(trim(t_ex.hour),2,fill='0')+':'+ $
                 strpad(trim(t_ex.minute),2,fill='0')+':'+ $
                 strpad(trim(t_ex.second),2,fill='0')
   datetimeend=''
  ;
   sdo_orderjsoc, datetimestart, $
                  duration, $
                  input[i].x, $
                  input[i].y, $
                  email, $
                  'My Name', $
                  cadence=cadence, $
                  xsize=xsize, $
                  ysize=ysize, requestidents,requestsizes, $
                  wavs=wavs, $
                  waitduration=5., $
                  notrack=notrack
  ;
   input[i].requestid=requestidents
  ;
   output[i].requestid=requestidents
   output[i].requestsize=requestsizes
   output[i].tstart=datetimestart
   output[i].tend=datetimeend
ENDFOR

END
