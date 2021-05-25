
FUNCTION spk_get_ch_data, ttime, count=count, area_cutoff=area_cutoff

;+
; NAME:
;     SPK_GET_CH_DATA
;
; PURPOSE:
;     Returns coronal hole position information using the HEK. 
;
; CATEGORY:
;     Coronal holes
;
; CALLING SEQUENCE:
;     Result = SPK_GET_CH_DATA( Ttime )
;
; INPUTS:
;     Ttime:   A string giving the time in a standard SSW format.
;
; OPTIONAL INPUTS:
;     Area_Cutoff: Coronal holes are only included in the output if
;                  they have an area greater than AREA_CUTOFF
;                  arcsec^2. The default is 100.
;
; OUTPUTS:
;     A structure with the tags
;      .start_time   Start time for CH specification (string).
;      .end_time     End time for CH specification (string).
;      .px    List containing CH polygon X-positions.
;      .py    List containing CH polygon Y-positions.
;      .area  List containing CH polygon areas (arcsec^2).
;
; OPTIONAL OUTPUTS:
;     Count:  Integer giving number of coronal holes found.
;
; EXAMPLE:
;     IDL> data=spk_get_ch_data('28-feb-2017 10:30')
;     IDL> x=data.px[1]
;     IDL> y=data.py[1]
;     IDL> p=plot(x,y)
;
; MODIFICATION HISTORY:
;     Ver.1, 20-Apr-2021, Peter Young
;-


IF n_params() LT 1 THEN BEGIN
   print,'Use:  IDL> data = spk_get_ch_data( Time [, count=, area_cutoff= ] )'
   count=0
   return,-1
ENDIF 

IF n_elements(area_cutoff) EQ 0 THEN area_cutoff=100. ELSE area_cutoff=float(area_cutoff)

output={start_time: '', END_time: '', $
        px: list(), py: list(), area: list()}

; I check +/- 5mins either side of the AIA map time for coronal holes
; in the HEK.
;
map_tai=anytim2tai(ttime)
t1_tai=map_tai-300.
t2_tai=map_tai+300.
t1_utc=anytim2utc(t1_tai,/ccsds)
t2_utc=anytim2utc(t2_tai,/ccsds)
query=ssw_her_make_query(t1_utc,t2_utc,/ch,/quiet)
her=ssw_her_query(query,/str,/quiet)


IF n_tags(her) NE 0 THEN BEGIN
;
; SPOCA seems to be the most reliable
;
   k=where(strlowcase(her.ch.required.frm_name) EQ 'spoca',nk)
  ;
   IF nk NE 0 THEN BEGIN 
      ch_data=her.ch[k]
      nch=n_elements(ch_data)
     ;
      output.start_time=ch_data[0].required.event_starttime
      output.end_time=ch_data[0].required.event_endtime
      count=0
      FOR j=0,nch-1 DO BEGIN 
         bound_chaincode=ch_data[j].optional.bound_chaincode
 
         i0=strpos(bound_chaincode,'(',/reverse_search)
         i1=strpos(bound_chaincode,')')
         str1=strmid(bound_chaincode,i0+1,i1-i0-1)
         bits=strsplit(str1,',',/extract)
         np=n_elements(bits)
         px=fltarr(np)
         py=fltarr(np)
        ;
         FOR i=0,np-1 DO BEGIN
            xy_str=strsplit(bits[i],' ',/extract)
            px[i]=float(xy_str[0])
            py[i]=float(xy_str[1])
         ENDFOR
        ;
        ; Here I compute the polygon's area. If it's 
         area = 0
         ii=np-1
         FOR k=0,np-1 DO BEGIN
            area=area+ (px[ii]+px[k])*(py[ii]-py[k])
            ii=k
         ENDFOR
         area=area/2.
        ;
         IF area GE area_cutoff THEN BEGIN 
            output.px.add,px
            output.py.add,py
            output.area.add,area
            count=count+1
         ENDIF 
      ENDFOR
   ENDIF 
ENDIF ELSE BEGIN
   junk=temporary(output)
   count=0
   return,-1
ENDELSE


return,output

END

