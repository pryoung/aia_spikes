

FUNCTION spk_plot_context, group, index, dir, boxsiz=boxsiz, buffer=buffer, $
                           quiet=quiet, text=text, ch=ch, data_ch=data_ch

;+
; NAME:
;     SPK_PLOT_CONTEXT
;
; PURPOSE:
;     For the specified spike group event, this routine retreives an
;     AIA synoptic image and extracts a sub-region. It then plots this
;     region, over-plots the spike location, and also over-plots the
;     locations of nearby spike events.
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     Result = SPK_PLOT_CONTEXT( Group, Index )
;
; INPUTS:
;     Group:  A structure array in the format returned by
;             SPK_GROUP_SPIKES.
;     Index:  An integer specifying the entry within GROUPS that
;             should be plotted.
; OPTIONAL INPUTS:
;     Boxsiz:  Specifies the size of the cutout box in arcsec. The box
;              will have size BOXSIZ*2+1. The default is 200 arcsec.
;     Dir:    Top directory where context files are stored. Used to
;             determine if we should proceed to make the
;             plot. Generally you will only use this as part of a
;             batch job. 
;	
; KEYWORD PARAMETERS:
;     BUFFER:  If set, then the plot is sent to the buffer rather than
;              displayed on screen.
;     QUIET:   If set, then text information is not displayed in the
;              IDL window.
;
; OUTPUTS:
;     Returns an IDL plot object containing the context image with the
;     location of event INDEX plotted as a blue cross. Other events
;     within the field of view are over-plotted with their index
;     numbers. Information about the plotted events is printed to the
;     IDL window.
;
;     If a problem is found then -1 is returned.
;
; OPTIONAL OUTPUTS:
;     Text:  A string array containing the text that is sent to the IDL
;     window (unless /quiet is set).
;
; EXAMPLE:
;     IDL> group=spk_group_events(spikes)
;     IDL> p=spk_plot_context(group,23)
;
; MODIFICATION HISTORY:
;     Ver.1, 09-Apr-2021, Peter Young
;     Ver.2, 12-Apr-2021, Peter Young
;        Fixed bug in /quiet implementation.
;     Ver.3, 20-Apr-2021, Peter Young
;     Ver.4, 08-Sep-2021, Peter Young
;        Fixed problem when a location is above the limb
;        (rot_xy doesn't work).
;     Ver.5, 09-Sep-2021, Peter Young
;        Switched from aia_rgb_table to eis_mapper_aia_rgb when
;        setting color table.
;-


IF n_params() LT 2 THEN BEGIN
   print,'Use:  IDL> p=spk_plot_context(group,index,dir [,/buffer,/quiet,boxsiz=]'
   return,-1
ENDIF 


;
; This performs a check on DIR. If the sub-directory for INDEX is
; missing, then I exit. (This can happen if the sub-directory has been
; manually deleted because a false event was found.)
;
IF n_elements(dir) NE 0 THEN BEGIN 
   list=file_search(concat_dir(dir,'*'),/test_dir,count=n)
   requestid=file_basename(list)
  ;
   chck=where(requestid EQ group[index].requestid,nk)
   IF nk EQ 0 THEN BEGIN
      print,'% SPK_PLOT_CONTEXT: The spike event does not have cutout frames. Returning...'
      return,-1
   ENDIF
ENDIF 

wave=group[index].wave
n=n_elements(group)

IF index LT 0 OR index GE n THEN BEGIN
   print,'% SPK_PLOT_CONTEXT: INDEX should take a value between 0 and '+trim(n-1)+'. Returning...'
   return,-1
ENDIF 

;
; Get a synoptic full disk image to use for context plots.
;
t_tai=anytim2tai(group[index].time_range)
t_ref_tai=0.5*(max(t_tai)+min(t_tai))
fd_map=eis_mapper_aia_map(t_ref_tai,wave,/quiet)





;
; Rotate all of the group events to the AIA map time.
;
xy=fltarr(n,2)
FOR i=0,n-1 DO BEGIN
   IF group[i].r LT 940. THEN BEGIN 
      xy[i,*]=rot_xy(group[i].x,group[i].y,tstart=group[i].time_range[0],tend=fd_map.time)
   ENDIF ELSE BEGIN
      xy[i,*]=[group[i].x,group[i].y]
   ENDELSE
ENDFOR

;
; Get the cutout
;
IF n_elements(boxsiz) EQ 0 THEN boxsiz=200.
xy_ref=reform(xy[index,*])
xrange=xy_ref[0]+[-boxsiz,boxsiz]
yrange=xy_ref[1]+[-boxsiz,boxsiz]
sub_map,fd_map,smap,xrange=xrange,yrange=yrange


in_events=bytarr(n)
FOR i=0,n-1 DO BEGIN
   IF i NE index THEN BEGIN 
      IF xy[i,0] GE xy_ref[0]-boxsiz AND xy[i,0] LE xy_ref[0]+boxsiz AND $
         xy[i,1] GE xy_ref[1]-boxsiz AND xy[i,1] LE xy_ref[1]+boxsiz THEN in_events[i]=1b
   ENDIF 
ENDFOR 


;
; Plot the AIA image.
;
r=plot_map_obj(smap,dim=[400,400],margin=0,rgb_table=eis_mapper_aia_rgb(wave), $
               /log,dmin=dmin,buffer=buffer, $
               pos=[0.10,0.08,1,1], $
               xmin=1,ymin=1,xtitle='',ytitle='',title='', $
               xtickdir=1,ytickdir=1, $
               xticklen=0.015,yticklen=0.015,xth=2,yth=2)

;
; Plot coronal hole if /ch set or data_ch specified.
; It looks like the coronal hole position is referenced to end_time,
; so I rotate the polygon positions from end_time to the map time. 
;
IF n_tags(data_ch) EQ 0 THEN BEGIN
   IF keyword_set(ch) THEN data_ch=spk_get_ch_data(smap.time)
ENDIF
;
IF n_tags(data_ch) THEN BEGIN
   nch=data_ch.px.count()
   t_ch_tai=anytim2tai(data_ch.end_time)
   FOR i=0,nch-1 DO BEGIN
      t_tai=anytim2tai(smap.time)
     ;
      xy_ch=rot_xy(data_ch.px[i],data_ch.py[i],tstart=data_ch.end_time,tend=smap.time)
     ;
      pch=plot(/overplot,xy_ch[*,0],xy_ch[*,1], $
               xrange=r.xrange,yrange=r.yrange,color='dodger blue',thick=2)
   ENDFOR 
ENDIF 
   
;
; Print label in bottom-left corner.
;
rtime=text(/data,xrange[0]+5,yrange[0]+5, $
           'Event '+trim(index+1)+', '+anytim2utc(/ccsds,/time,/trunc,smap.time), $
           color='white',font_size=12)

;
; Plot the location of selected event (blue cross)
;
rx=plot(/overplot,xy_ref[0]*[1,1],xy_ref[1]*[1,1],symbol='+',sym_size=4, $
        color='dodger blue',sym_thick=3)




text='*This event:'
text=[text,string(format='(i8,"  (",i4,",",i4,")",a10," -",a10)',index+1, $
         xy_ref[0],xy_ref[1], $
         anytim2utc(group[index].time_range[0],/ccsds,/time,/trunc), $
         anytim2utc(group[index].time_range[1],/ccsds,/time,/trunc))]

;
; Plot other events within field-of-view.
;
IF max(in_events) EQ 1 THEN BEGIN
   text=[text,'*Nearby events: ']
   FOR i=0,n-1 DO BEGIN
      IF in_events[i] EQ 1 THEN BEGIN
         rn=text(/data,align=0.5,vertical_align=0.5,xy[i,0],xy[i,1],trim(i+1), $
                 font_size=14,color='white')
         text=[text,string(format='(i8,"  (",i4,",",i4,")",a10," -",a10)',i+1, $
                           xy[i,0],xy[i,1], $
                           anytim2utc(group[i].time_range[0],/ccsds,/time,/trunc), $
                           anytim2utc(group[i].time_range[1],/ccsds,/time,/trunc))]
      ENDIF
   ENDFOR
ENDIF

text=[text,'*Note: events labeled from 1 upwards.']

IF NOT keyword_set(quiet) THEN BEGIN
   nt=n_elements(text)
   FOR i=0,nt-1 DO print,text[i]
ENDIF 


return,r

END
