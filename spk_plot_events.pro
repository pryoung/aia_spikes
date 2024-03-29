
function spk_plot_events, group, wave=wave, number=number, ch=ch, nplots=nplots,  $
                          list=list, _extra=_extra, dmin=dmin, image_time=image_time, $
                          color_ch=color_ch, color_cross=color_cross, $
                          no_data=no_data

;+
; NAME:
;     SPK_PLOT_EVENTS
;
; PURPOSE:
;     From the group structure this routine downloads a synoptic image
;     and shows where the events occur.
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     Result = SPK_PLOT_EVENTS( Group )
;
; INPUTS:
;     Group:  The structure produced by spk_group_spikes.pro.
;
; OPTIONAL INPUTS:
;     Wave:   Specify the AIA wavelength to show. The default is 193.
;     Nplots:  A 2-element integer array [N,M]. The first element, N,
;              tells the software the number of plots you intend to
;              produce, and M tells the software that on this call you
;              plotting number M. So if there are 100 events in group,
;              then [2,1] means events 1-50 will be displayed in the
;              current plot.
;     Dmin:   Specifies minimum DN value to use for plotting. If not
;             set, then 100 is used.
;     Image_Time:  Specifies the time for which you want the AIA
;             image. Should be specified in a standard Solarsoft
;             format. If not specified, then it is set to the mid-time
;             between the minimum and maximum times in GROUP.
;     Color_Ch: A string specifying the color of the coronal hole
;               contour (if /CH has been set. The default is 'dodger
;               blue'. 
;	
; KEYWORD PARAMETERS:
;     NUMBER:  If set, then the event locations are plotted with the
;              index number of the event.
;     CH:     Overplot the SPoCA coronal hole outlines from the HEK.
;     NO_DATA: If set, then the locations of the spike events are
;              not plotted.
;
; OUTPUTS:
;     Returns an IDL plot object containing the AIA image, with the
;     locations of the events over-plotted.
;
; EXAMPLE:
;     IDL> p=spk_plot_events(group)
;     IDL> p=spk_plot_events(group,wave=171)
;
; MODIFICATION HISTORY:
;     Ver.1, 18-Mar-2016, Peter Young
;     Ver.2, 21-Mar-2016, Peter Young
;        now use different colors for different event durations.
;     Ver.3, 24-Mar-2021, Peter Young
;        now calls eis_mapper_aia_map to get the AIA image.
;     Ver.4, 30-Mar-2021, Peter Young
;        added /number and /ch keywords.
;     Ver.5, 15-Jun-2021, Peter Young
;        added DMIN= optional input; expanded header.
;     Ver.6, 14-Jul-2021, Peter Young
;        added IMAGE_TIME= optional input.
;     Ver.7, 09-Sep-2021, Peter Young
;        Switched from aia_rgb_table to eis_mapper_aia_rgb when
;        setting color table.
;     Ver.8, 30-Sep-2021, Peter Young
;        Added color_ch= and color_cross= optional inputs.
;     Ver.9, 04-Aug-2021, Peter Young
;        Added /no_data keyword.
;-


IF n_elements(wave) EQ 0 THEN wave=193

IF n_elements(nplots) NE 0 AND n_elements(nplots) NE 2 THEN BEGIN
   print,'% SPK_PLOT_EVENTS: NPLOTS should be given as [N,M] - see header. Returning...'
   return,-1
ENDIF

IF n_elements(dmin) EQ 0 THEN dmin=100.

IF n_elements(color_ch) EQ 0 THEN color_ch='dodger blue'

IF n_elements(color_cross) EQ 0 THEN color_cross=['dodger blue','yellow','white','red']


n=n_elements(group)
IF n_elements(nplots) EQ 2 THEN BEGIN
   d=ceil(float(n)/float(nplots[0]))
   i0=(nplots[1]-1)*d
   i1=min([(nplots[1])*d-1,n-1])
   g=group[i0:i1]
ENDIF ELSE BEGIN
   g=group
ENDELSE
n=n_elements(g)

;
; Get the time for which the AIA image is needed.
;
IF n_elements(image_time) NE 0 THEN BEGIN
   t_ref_tai=anytim2tai(image_time)
ENDIF ELSE BEGIN 
   t_tai=anytim2tai(g.time_range)
   t_ref_tai=0.5*(max(t_tai)+min(t_tai))
ENDELSE 

t_dur=anytim2tai(g.time_range[1])-anytim2tai(g.time_range[0])

map=eis_mapper_aia_map(t_ref_tai,wave)


p=plot_map_obj(map,/log,dmin=dmin,rgb_table=eis_mapper_aia_rgb(wave),font_size=12, $
              xrange=[-1100,1100],yrange=[-1100,1100],_extra=_extra)

dtheta=2.*!pi/float(n)
str={theta: 0., x: 0., y: 0., ind: -1}
pts=replicate(str,n)
pts.theta=findgen(n)*dtheta-!pi

FOR i=0,n-1 DO BEGIN
   xy=rot_xy(g[i].x,g[i].y,tstart=g[i].time_range[0],tend=map.time)
   phi=atan(xy[1]/xy[0])
   k=where(pts.ind EQ -1)
   getmin=min(abs(phi-pts[k].theta),imin)
   pts[k[imin]].ind=i+1
   pts[k[imin]].x=xy[0]
   pts[k[imin]].y=xy[1]
ENDFOR 



ang=2.*!pi*round(randomu(seed,n)*12.)/12.

IF NOT keyword_set(no_data) THEN BEGIN 
icol_array=intarr(n)
FOR i=0,n-1 DO BEGIN
   CASE 1 OF
      t_dur[i] LE 60.: icol=0
      t_dur[i] GT 60. AND t_dur[i] LE 300.: icol=1
      t_dur[i] GT 3600.: icol=3
      ELSE: icol=2
   ENDCASE
   icol_array[i]=icol
   xy=rot_xy(g[i].x,g[i].y,tstart=g[i].time_range[0],tend=map.time)

   CASE 1 OF
      keyword_set(list): BEGIN
         xp=80.*cos(pts[i].theta)+pts[i].x
         yp=80.*sin(pts[i].theta)+pts[i].y
         qt=text(align=0.5,vertical_align=0.5,xp,yp,trim(pts[i].ind),color='white', $
                 font_size=12,/data)
         a=plot(/overplot,[pts[i].x,xp],[pts[i].y,yp],th=2,color='white')
      END 
      keyword_set(number): BEGIN 
         dx=80*cos(ang[i]) & dy=80*sin(ang[i])
         xy1=[xy[0]+dx,xy[1]+dy]
         a=plot([xy[0],xy1[0]],[xy[1],xy1[1]],/overplot,color='white',th=2)
     ;
         CASE 1 OF
            round(dx) EQ 0: align=0.5
            dx GE 0: align=0
            ELSE: align=1
         ENDCASE
     ;
         CASE 1 OF
            round(dy) EQ 0: vertical_align=0.5
            dy GE 0: vertical_align=0
            ELSE: vertical_align=1
         ENDCASE
     ;
         qt=text(align=align,vertical_align=vertical_align,xy1[0],xy1[1],trim(i+1),color='white', $
                 font_size=12,/data)
      END
     ;
      ELSE: BEGIN 
         q=plot(xy[0]*[1,1],xy[1]*[1,1],symbol='+',color=color_cross[icol],/overplot,sym_thick=2)
      END
   ENDCASE 
 ENDFOR
ENDIF 

;
; I check +/- 5mins either side of the AIA map time for coronal holes
; in the HEK.
;
IF keyword_set(ch) THEN BEGIN
   map_tai=anytim2tai(map.time)
   t1_tai=map_tai-300.
   t2_tai=map_tai+300.
   t1_utc=anytim2utc(t1_tai,/ccsds)
   t2_utc=anytim2utc(t2_tai,/ccsds)
   query=ssw_her_make_query(t1_utc,t2_utc,/ch,/quiet)
   her=ssw_her_query(query,/str,/quiet)
   IF n_tags(her) NE 0 THEN BEGIN
      nch=n_elements(her.ch)
     ;
      FOR j=0,nch-1 DO BEGIN 
         bound_chaincode=her.ch[j].optional.bound_chaincode
 
         i0=strpos(bound_chaincode,'(',/reverse_search)
         i1=strpos(bound_chaincode,')')
         str1=strmid(bound_chaincode,i0+1,i1-i0-1)
         bits=strsplit(str1,',',/extract)
         np=n_elements(bits)
         px=fltarr(np)
         py=fltarr(np)
         FOR i=0,np-1 DO BEGIN
            xy_str=strsplit(bits[i],' ',/extract)
            px[i]=float(xy_str[0])
            py[i]=float(xy_str[1])
         ENDFOR
         r=plot(px,py,color=color_ch,/overplot,xrange=p.xrange,yrange=p.yrange,th=2)
      ENDFOR
   ENDIF ELSE BEGIN
      print,'% SPK_PLOT_EVENTS: there are no coronal holes defined in the HEK for this time.'
   ENDELSE 
 ENDIF 

IF NOT keyword_set(no_data) THEN BEGIN 
  print,'   Color    Lifetime         No. events'
  k=where(icol_array EQ 0,nk)
  print,'   Blue     <= 60 seconds    '+trim(nk)
  k=where(icol_array EQ 1,nk)
  print,'   Yellow   <= 300 seconds   '+trim(nk)
  k=where(icol_array EQ 2,nk)
  print,'   White    > 300 seconds    '+trim(nk)
  k=where(icol_array EQ 3,nk)
  print,'   Red      > 1 hour         '+trim(nk)
ENDIF

return,p



END
