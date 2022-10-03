#
# Author: Mike Bush
# Company: ECCO Select
# Description: Serve support logs for Einblick
# 
from flask import Flask


app = Flask("EinblickLogs",
            static_url_path='',
            static_folder='/app/support/einblick-logs',
            template_folder='/app/support/einblick-logs')



print("service logs...")


app.run(host="0.0.0.0",
        port=18080)
