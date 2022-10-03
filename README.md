# Einblick Support Tools


## Tool einblick-dump.sh:

Utility to export Einblick data collection to a ZIP file

## Arguments:

/app/support/einblick-dump.sh MONGO_COLLECTION_NAME<br>
MONGO_COLLECTION_NAME– Name of the MongoDB collection inside the Einblick DB<br>

## Tool einblick-s3send.sh:

Utility to send a file to the specified Einblick S3 bucket folder.

## Arguments:

/app/support/einblick-s3send.sh USER_KEY USER_SECRET S3_FOLDER FILE<br>
USER_KEY – Amazon User Key<br>
USER_SECRET – Amazon User Secret<br>
S3_FOLDER – Destination Folder in S3 bucket<br>
FILE – File to send to the S3 folder<br>

## Tool einblick-mgosend.sh:

Utility to send a Einblick data collection directly to the Einblick S3 extract bucket folder.

## Arguments:

/app/support/einblick-mgosend.sh USER_KEY USER_SECRET FILE<br>


USER_KEY – Amazon User Key<br>
USER_SECRET – Amazon User Secret<br>
FILE – File to send to the S3 folder named "extract"<br>

# Einblick Auto Support Bundle Tool

## Description:

This tool is used to extract support information and logs from the kubernetes instance of Einblick. These support bundles must be sent to Einblick for analysis. Historically, this task was
manual, needing to use the Einblick Administrative Console UI to generate and download the support file from a browser. Additionally, a manual step of attaching and sending by email was
needed. The new process extracts the support information and uploads them to an Einblick provided S3 bucket, eliminating the need for any manual intervention.


## Tool Arguments:

/app/support/einblick-support-bundle.sh USER_KEY USER_SECRET S3_FOLDER<br>
USER_KEY – Amazon User Key<br>
USER_SECRET – Amazon User Secret<br>
S3_FOLDER – Destination Folder in S3 bucket<br>


## scheduled.log:

```
Log for the scheduled job output
```
## support-bundle.log:

```
Log for the kubectl support bundle generation output
```
## support-bundle-*.gz:


```
Support bundle file to send
```
## Crontab Entry for Support Bundle:

5 6,10,14,16,18 * * 1,2,3,4,5 /app/support/einblick-support-bundle.sh KEY SECRET scheduled &> /app/support/scheduled.log

### Scheduled:

```
5 6,10,14,16,18 * * 1,2,3,4,5 == “At minute 5 past hour 6, 10, 14, 16, and 18 on Monday, Tuesday, Wednesday, Thursday, and Friday.”
```
## Crontab Entry for UI Monitor:

*/5 * * * * /app/support/einblick-monitor.sh KEY SECRET monitored &> /app/support/monitor.log

### Scheduled:

```
*/5 * * * * == “Every 5 minutes”
```

## Einblick Support Log Server:

To provide better ease and visibility to the Einblick logs, a python-based Flask server can be used to server the logs in a convenient web based format.  The server will pull the data from the last run of the log support bundle extraction process and generate an index page for the logs that exist.  You can then view all the logs generated by Einblick from the browser.  For ease of use create a virtual python environment and install Flask with pip.
### Starting Example Log Server:


#### Change to server directory:

```
cd /app/support/server
```
#### Activate Virtual Environment:

```
source env/bin/activate  
```
#### Start Flask Server in the Background:

```
python server_logs.py &
```

### URL:

http://my.server:18080/index.html

## Screenshots
![Index Page](screenshots/log-index.png?raw=true)
![Log Example](screenshots/log-example.png?raw=true)
