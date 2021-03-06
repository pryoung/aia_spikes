;+
; 25-May-2021, Peter Young
;
; This is an example script showing the workflow for processing spikes
; for a particular date, time period and AIA channel.
;
; Run this script from the IDL command line:
;   IDL> .r process_spikes
;
; This example should take about 3-6 hours to run.
;
; You can also run this script using a cron job. See the page:
;  https://pyoung.org/quick_guides/idl_cron.html
;
; 01-Sep-2021, PRY: couple of minor edits.
; 08-Sep-2021, PRY: now calls spk_get_outdir.
;-


date='28-feb-2017'
wave=171
time_range=['09:00','12:00']
email=''   ; <--- Put your registered JSOC email
my_data_dir=''   ; <--- Specify a directory where output will go

list=spk_get_time_range(date,wave,time_range=time_range,metadata=mdata)
;
outdir=spk_get_outdir(date,wave,my_data_dir=my_data_dir)
;
save,file=concat_dir(outdir,'metadata.save'),mdata
spikes=spk_process_sequence(list,info=info)
save,file=concat_dir(outdir,'spikes.save'),spikes,info
group=spk_group_spikes(spikes)
spk_request_cutouts,group,wave,email,output=output
save,file=concat_dir(outdir,'group.save'),group
spk_download_cutouts,output,outdir=outdir
spk_respike_groups,date,wave,outdir,metadata=mdata
spk_make_movie_frames,group,outdir  ; use /linear, if necessary.
spk_movie_ffmpeg,group,outdir,/log
junk=temporary(mdata)

exit

