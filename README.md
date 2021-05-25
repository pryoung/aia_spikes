# aia_spikes
Software for processing spikes in AIA data

OVERVIEW
========
This software was written in the IDL language and it attempts to identify real solar events within the discarded "spike" data produced by the AIA instrument onboard the Solar Dynamics Observatory (SDO). The sections below describe how to use the software.

REQUIREMENTS
============
IDL version 8.5 or higher is recommended.

You must be using the Solarsoft IDL distribution.

Set the environment variable $AIA_SPIKES in your idl_startup.pro file to the location where you want to store the downloaded spikes files.

Make sure you have the set of "SPK" IDL routines (this repository).

Make sure you have the routine sdo_orderjsoc.

Make sure you have a registered account at JSOC (you need the email address that the account is registered to).

Make sure ffmpeg is installed on your computer (for making movies).


DOWNLOAD SPIKES FILES
=====================
Go to the JSOC Export Data page:

http://jsoc.stanford.edu/ajax/exportdata.html

Submit a request for an entire day's worth of spikes for one filter by putting the following in the "RecordSet" box:

aia.lev1_euv_12s[2017.02.28_00:00/1d][193]{spikes}

For "Method", use url-tar.

Submit the request and wait till it gets assigned a RequestID.

Now go into IDL and do:

IDL> sdoc_jsoc_check_status, RequestID

If the routine says the data are ready to be downloaded, then run the above routine again, but give the keyword /download. This unpacks the tar file giving the spikes files.

Now ingest the files into your $AIA_SPIKES directory:

IDL> list=file_search('*.spikes.fits')
IDL> aia_ingest_spikes,list


PLOT SPIKE TIME SERIES
======================
(You should do this step if you plan to extract a sub-set of the day's spikes files for your analysis. For example, you will see periods when the number of spikes are low, implying the number of particle hits is low.) 

Here we plot how the number of spikes varies during the day.

IDL> d=spk_get_metadata('28-feb-2017',171)
IDL> utplot,d.t_obs,d.nspikes,/xsty


PROCESS SPIKE DATA
==================
Edit the top few lines of the "process_spikes.pro" file to customize it for yourself and set the day and wavelength that you're interested
in.

Then run the file:

IDL> .r process_spikes

After some time (1-3 hours?) you should have an html file that contains the movies and light curves for each event. Depending on how you set things up, it should be in a directory called something like:

~/my_data/aia_spikes/2017/02/28/0171/

