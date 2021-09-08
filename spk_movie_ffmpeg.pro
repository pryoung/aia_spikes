
PRO spk_movie_ffmpeg, group, dir, log=log

;+
; NAME:
;     SPK_MOVIE_FFMPEG
;
; PURPOSE:
;     Takes the spike movie frames (generated with
;     SPK_MAKE_MOVIE_FRAMES) and compiles them into movies by spawning
;     a call to FFMPEG.
;
; CATEGORY:
;     SDO; AIA; spikes.
;
; CALLING SEQUENCE:
;     SPK_MOVIE_FFMPEG, Group, Dir
;
; INPUTS:
;     Group: The output from the routine spk_group_events.pro.
;     Dir:   Directory containing the collection of cutouts.
;	
; KEYWORD PARAMETERS:
;     LOG:   If set, then the output file will be called 'movie_log.mp4'.
;
; OUTPUTS:
;     For each sub-directory within DIR, the routine creates an mp4
;     file containing the images stored in the 'frames'
;     subdirectory. The filename will be 'movie.mp4' unless the /log
;     keyword is set.
;
; RESTRICTIONS:
;     The user must have FFMPEG installed. If you have a Mac, try
;     installing with homebrew.
;
; MODIFICATION HISTORY:
;     Ver.1, 09-Apr-2021, Peter Young
;     Ver.2, 08-Sep-2021, Peter Young
;       Removed pattern_type from ffmpeg call; changed how framefiles
;       is specified; changed from h264 to libx264
;-


IF n_params() LT 2 THEN BEGIN
   print,'Use:  IDL> spk_movie_ffmpeg, group, dir [, /log]'
   return
ENDIF 

list=file_search(concat_dir(dir,'*'),/test_dir,count=n)

FOR i=0,n-1 DO BEGIN
   framedir=concat_dir(list[i],'frames')
;   framefiles=concat_dir(framedir,'*.png')
   framefiles=concat_dir(framedir,'image%04d.png')
   IF keyword_set(log) THEN logstr='_log' ELSE logstr=''
   movfile=concat_dir(list[i],'movie'+logstr+'.mp4')
   chck=file_info(movfile)
   IF chck.exists EQ 1 THEN file_delete,movfile
  ;
   spawn_command="ffmpeg -r 15 -i '"+framefiles+"' -vcodec libx264 -pix_fmt yuv420p -crf 20 "+movfile
   spawn,spawn_command
ENDFOR 



END
