
FUNCTION spk_group_spikes, spike_str

;+
; NAME:
;      SPK_GROUP_SPIKES()
;
; PURPOSE:
;      Takes the spike structure from spk_process_sequence and then
;      groups the events together based on spatial location and timing
;      information. 
;
; CATEGORY:
;      SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;      Result = SPK_GROUP_SPIKES( Spike_Str )
;
; INPUTS:
;      Spike_Str:   This is the structure that is produced by
;                   spk_process_sequence. 
;
; OUTPUTS:
;      A structure of the same format as SPIKE_STR but reduced in size
;      to contain only different events. Note that the tag TIME_RANGE
;      is modified to give the time range over which the event lasts
;      (taking into account all the individual instances).
;
; EXAMPLE:
;      IDL> spikes=spk_process_sequence('*spikes.fits')
;      IDL> group=spk_group_spikes(spikes)
;
; MODIFICATION HISTORY:
;      Ver.1, 18-Mar-2016, Peter Young
;      Ver.2, 6-Apr-2016, Peter Young
;        Rotate coordinates of events when doing spatial check.
;      Ver.3, 26-Mar-2021, Peter Young
;        Now apply a time check (see time_check variable) when
;        matching events to a group; now prints messages to indicate
;        progress.
;      Ver.4, 31-Mar-2021, Peter Young
;        Updated header.
;-



n=n_elements(spike_str)

;
; 'group' initially only contains the first entry in spike_str
;
group=spike_str[0]

;
; Events belong to the same group if they occur within a radius of
; sep_check arcsec of each other, and are within 5 mins of each
; other. 
;
sep_check=5.0   ; in arcsec
time_check=300. ; seconds


FOR i=1,n-1 DO BEGIN
   IF round(float(i+1)*10/(n)) MOD 10 EQ 0 THEN print,'Processing '+trim(i+1)+' of '+trim(n)
   ng=n_elements(group)
   sep=fltarr(ng)
   tend=spike_str[i].time_range[0]
   xx=spike_str[i].x
   yy=spike_str[i].y
 ;
 ; Go through each member of 'group' and see if spike_str[i] matches
 ; any of them. The coordinates are rotated when checking.
 ;
   FOR j=0,ng-1 DO BEGIN
      xy=rot_xy(group[j].x,group[j].y,tstart=group[j].time_range[0],tend=tend)
      sep[j]=sqrt( (xx-xy[0])^2 + (yy-xy[1])^2 )
   ENDFOR
 ;
 ; Check if there's a match with a previous event
 ;
   k=where(sep LT sep_check,nk)
   IF nk EQ 0 THEN BEGIN
      group=[group,spike_str[i]]
   ENDIF ELSE BEGIN
      new_tai=anytim2tai(spike_str[i].time_range)
      swtch=0
      FOR j=0,nk-1 DO BEGIN 
         g_tai=anytim2tai(group[k[j]].time_range)
         dtai1=g_tai[0]-new_tai[1]
         dtai2=new_tai[0]-g_tai[1]
        ;
         IF dtai2 GT 0 AND dtai2 LT time_check THEN BEGIN
            group[k[j]].time_range[1]=spike_str[i].time_range[1]
            swtch=1
         ENDIF 
         IF dtai1 GT 0 AND dtai1 LT time_check THEN BEGIN
            group[k[j]].time_range[0]=spike_str[i].time_range[0]
            swtch=1
         ENDIF
         IF dtai1 LE 0 AND dtai2 LE 0 THEN BEGIN
            swtch=1
         ENDIF 
            
         IF swtch EQ 1 THEN break
      ENDFOR
      IF swtch EQ 0 THEN group=[group,spike_str[i]]
   ENDELSE 
ENDFOR 

return,group

END
