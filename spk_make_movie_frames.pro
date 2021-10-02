
PRO spk_make_movie_frames, group, dir, wave=wave, no_processing=no_processing, $
                           linear=linear, ffmpeg=ffmpeg, clean=clean


;+
; NAME:
;      SPK_MAKE_MOVIE_FRAMES
;
; PURPOSE:
;      Creates an mp4 movie from the despiked and respiked cutout
;      frames. Also creates a light curve for the spike event, writing
;      it to a png.
;
; CATEGORY:
;      SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;      SPK_MAKE_MOVIE_FRAMES, Dir, Group
;
; INPUTS:
;      Group: The output from the routine spk_group_events.pro.
;      Dir:   Directory containing the collection of cutouts.
;
; OPTIONAL INPUTS:
;      Wave:  Specify AIA wavelength. This is used to set the color
;             table for the images. (Default is 193.)
;	
; KEYWORD PARAMETERS:
;      NO_PROCESSING: If set, then the light curve png and movie are
;                     regenerated without creating new image frames.
;      LINEAR:   If set, then a linear intensity scaling is used for
;                the images. (Default is log scaling.)
;      FFMPEG:   If set, then the routine calls SPK_MOVIE_FFMPEG to
;                create mp4 movies from the image frames. This
;                requires ffmpeg to be installed on the user's
;                computer.
;      CLEAN:    If set, then the respiked images are cleaned of
;                spikes by using the /clean keyword of sdo2map.pro. In
;                this case, the left image in the movie shows the
;                respiked images, and the right image shows the
;                respiked-despiked images. For the light curves, the
;                blue line shows the respiked data, and red line shows
;                the respiked-despiked data.
;
; OUTPUTS:
;      Creates the files 'movie.mp4' and 'light_curve.png' in the
;      directory DIR.
;
;      The blue line in the light curves shows the average intensity
;      within a 11x11 pixel box around the spike event, derived from
;      the original, despiked data. The red line shows the same light
;      curve from the respiked data. (Thus the red line is always
;      equal-to or higher than the blue line.) If the /clean keyword
;      is set, then the light curves are different (see above).
;
;      The movie has two panels. The left shows the original, despiked
;      images, and the right shows the new, respiked images. If the
;      /clean keyword is set, then the images are different (see
;      above). 
;
; EXAMPLE:
;      IDL> spk_make_movie_frames, 'my_cutouts', group
;
; MODIFICATION HISTORY:
;      Ver.1, 31-Mar-2021, Peter Young
;      Ver.2, 06-Apr-2021, Peter Young
;        Added nbox.
;      Ver.3, 07-Apr-2021, Peter Young
;        Set color table properly; fixed bug with movie link when /log
;        set.
;      Ver.4, 20-Apr-2021, Peter Young
;        Now displays context image (4th column of output).
;      Ver.5, 21-Apr-2021, Peter Young
;        Now saves the light curves in the individual directories.
;      Ver.6, 07-May-2021, Peter Young
;        Added keyword /clean to do a comparison of the respiked
;        images with the cleaned images.
;      Ver.7, 08-Sep-2021, Peter Young
;        Directly specify width of movie frames rather than use the
;        resolution keyword; adjusted scaling for logarithmic movie
;        frames due to problems with 94 channel.
;      Ver.8, 09-Sep-2021, Peter Young
;        Switched from aia_rgb_table to eis_mapper_aia_rgb when
;        setting color table; now obtain directory list from the group
;        requestids.
;      Ver.9, 01-Oct-2021, Peter Young
;        Added /clean to header (no change to code); updated header to
;        better describe what /clean does.
;-


wave=group[0].wave

log=1b-keyword_set(linear)

requestid=group.requestid
list=concat_dir(dir,requestid)
n=n_elements(list)

;list=file_search(concat_dir(dir,'*'),/test_dir,count=n)

;
; Get a synoptic full disk image to use for context plots.
;
t_tai=anytim2tai(group.time_range)
t_ref_tai=0.5*(max(t_tai)+min(t_tai))
t_dur=anytim2tai(group.time_range[1])-anytim2tai(group.time_range[0])
fd_map=eis_mapper_aia_map(t_ref_tai,wave)

;
; This determines the size of the box used to obtain the light curve.
; The box is square with a length of nbox*2 + 1 pixels.
;
nbox=10

FOR i=0,n-1 DO BEGIN
   outdir=concat_dir(list[i],'frames')
   IF NOT keyword_set(no_processing) THEN BEGIN
      print,'======= Processing directory '+file_basename(list[i])+ $
            ' ('+trim(i+1)+' of '+trim(n)+') ========'
      chck=file_info(outdir)
      IF chck.exists EQ 0 THEN file_mkdir,outdir
      chck=file_search(outdir,'*.png',count=nf)
      IF nf NE 0 THEN file_delete,chck
  ;
      files=file_search(concat_dir(list[i],'*.fits'),count=m)
      files2=file_search(concat_dir(list[i],'respike'),'*.fits')
  ;
      IF keyword_set(clean) THEN BEGIN
         map=sdo2map(files2)
         map2=sdo2map(files2,/clean)
      ENDIF ELSE BEGIN 
         map=sdo2map(files)
         map2=sdo2map(files2)
      ENDELSE 
     ;
      c=sigrange(map.data,range=r,missing=0)
      IF keyword_set(linear) THEN BEGIN
         dmin=r[0]
         dmax=max(map.data)*0.90
         dmax2=max(map2.data)*0.90
      ENDIF ELSE BEGIN
;         dmin=max([r[0],10])
         dmin=max([r[0],1])
         dmax=max([max(map.data),2])
         dmax2=dmax
      ENDELSE 
     ;
      lc=fltarr(m)
      lc2=fltarr(m)
     ;
      s=size(/dim,map[0].data)
      nx=s[0] & ny=s[1]
     ;
      tt_jd=tim2jd(map.time)
      FOR j=0,m-1 DO BEGIN
         w=window(dim=[750,400],/buffer)
         p=plot_map_obj(map[j],rgb_table=eis_mapper_aia_rgb(wave), $
                        dmin=dmin,dmax=dmax, $
                        layout=[2,1,1],/current,xmin=1,ymin=1,log=log)
         lc[j]=average(map[j].data[nx/2-nbox:nx/2+nbox,ny/2-nbox:ny/2+nbox])
         q=plot_map_obj(map2[j],rgb_table=eis_mapper_aia_rgb(wave), $
                        dmin=dmin,dmax=dmax2, $
                        layout=[2,1,2],/current,xmin=1,ymin=1,log=log)
         lc2[j]=average(map2[j].data[nx/2-nbox:nx/2+nbox,ny/2-nbox:ny/2+nbox])
         outfile='image'+strpad(trim(j),4,fill='0')+'.png'
         outfile=concat_dir(outdir,outfile)
         w.save,outfile,width=750
         w.close
        ;
      ENDFOR
     ;
      k=where(group.requestid EQ file_basename(list[i]),nk)
      ig=k[0]
     ;
     ; Plot light curve
     ;
      title=string(format='("X: ",f7.1,", Y: ",f7.1)',group[ig].x,group[ig].y)
      p=plot(/buffer,tt_jd,lc2,xtickunits='time',xtickformat='(C(CHI2.2,":",CMI2.2))',color='red', $
             xth=2,yth=2,th=3,/xsty,dim=[600,400], $
             xtit='Time / HH:MM',ytit='Intensity / DN s!u-1!n', $
             ymin=1,xticklen=0.015,yticklen=0.015, $
             pos=[0.14,0.14,0.96,0.90],title=title,font_size=12)
      q=plot(/overplot,tt_jd,lc,color='blue',th=3)
      outfile=concat_dir(list[i],'light_curve.png')
      p.save,outfile,resolution=96
      p.close
      outfile=concat_dir(list[i],'light_curves.save')
      save,file=outfile,tt_jd,lc,lc2
     ;
     ; Create the context image.
      r=spk_plot_context(group,ig,dir,/buffer,/quiet,/ch)
      IF datatype(r) EQ 'OBJ' THEN BEGIN 
         outfile=concat_dir(list[i],'context.png')
         r.save,outfile,resolution=96
         r.close
      ENDIF 
     ;
      delvar,map,map2
   ENDIF 
  ;
ENDFOR


IF keyword_set(ffmpeg) THEN BEGIN
   spk_movie_ffmpeg, group, dir, log=log
ENDIF 

IF keyword_set(log) THEN logstr='_log' ELSE logstr=''
html_file=concat_dir(dir,'index'+logstr+'.html')
openw,lout,html_file,/get_lun

printf,lout,'<table>'
FOR i=0,n-1 DO BEGIN
   k=where(group.requestid EQ file_basename(list[i]),nk)
   ig=k[0]
  ;
   tprint=anytim2utc(group[ig].time_range[0],/ccsds,/time,/trunc)
   t_tai=anytim2tai(group[ig].time_range)
   dt_min=(t_tai[1]-t_tai[0])/60.
   printf,lout,'<tr>'
   printf,lout,'<td>'
   printf,lout,format='("Event ",i3,"<br>  X: ",f7.1,"<br>  Y: ",f7.1,"<br> Start: ",a10,"<br>  Dur(mins): ",f5.1," <br>")', $
          i+1,group[ig].x,group[ig].y,tprint,dt_min
   printf,lout,'<td><img src="'+concat_dir(file_basename(list[i]),'light_curve.png')+'"></td>'
   printf,lout,'<td> <video controls="controls" loop="true"><source src="'+concat_dir(file_basename(list[i]),'movie'+logstr+'.mp4')+'"></source>'
   printf,lout,'<td><img src="'+concat_dir(file_basename(list[i]),'context.png')+'"></td>'
   IF n_elements(text) NE 0 THEN BEGIN
      tdstr='<td>'
      FOR j=0,n_elements(text)-1 DO tdstr=tdstr+text[i]+'<br>'
      tdstr=tdstr+'</td>'
      printf,lout,tdstr
   ENDIF 
ENDFOR
printf,lout,'</table>'

free_lun,lout

END
