
FUNCTION spk_get_metadata, date, wave

;+
; NAME:
;     SPK_GET_METADATA
;
; PURPOSE:
;     Uses the JSOC to return metadata for all spikes files in a day
;     for a specified AIA filter.
;
; CATEGORY:
;     SDO; AIA; spikes
;
; CALLING SEQUENCE:
;     Result = SPK_GET_METADATA( Date, Wave )
;
; INPUTS:
;     Date:   A string containing the date in a standard format. For
;             example, '28-Feb-2017' or '2017-02-28'.
;     Wave:   An integer specifying an AIA EUV filter. For example,
;             171 or 193.
;
; OUTPUTS:
;     A structure array containing the metadata. The tags are:
;      .t_obs  Observation time.
;      .nspikes  Number of spikes.
;      .exptime  Exposure time (seconds).
;
; EXAMPLE:
;     IDL> data=spk_get_metadata('28-feb-2017',171)
;     IDL> utplot,data.t_obs,data.nspikes
;
; MODIFICATION HISTORY:
;     Ver.1, 06-Apr-2021, Peter Young
;-


t_ex=anytim2utc(/ex,date)
datetimestart=trim(t_ex.year)+'.'+ $
              strpad(trim(t_ex.month),2,fill='0')+'.'+ $
              strpad(trim(t_ex.day),2,fill='0')+'_'
datetimestart=datetimestart+'00:00'

url='http://jsoc.stanford.edu/cgi-bin/ajax/show_info?ds=aia.lev1_euv_12s['
url=url+datetimestart+'/24h]'
url=url+'['+trim(wave)+']{spikes}'
url=url+'&key=T_OBS,NSPIKES,EXPTIME'

print,'Querying JSOC...'
t0=systime(1)
sock_list,url,page
t1=systime(1)
print,format='("Query took: ",f8.2," seconds")',t1-t0

page=page[1:*]
page=strcompress(page)

n=n_elements(page)


data=strarr(n,3)

FOR i=0,n-1 DO data[i,*]=page[i].split(' ')

str={t_obs: '', nspikes: 0l, exptime: 0.}
output=replicate(str,n)

output.t_obs=data[*,0]
output.nspikes=long(data[*,1])
output.exptime=float(data[*,2])

return,output

END
