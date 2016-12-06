#!/bin/sh
# Make sure you replace the API and/or APP key below
# with the ones for your account


currenttime=$(date +%s)
echo $currenttime
curl  -X POST -H "Content-type: application/json" \
-d "{ \"series\" :
         [{\"metric\":\"registered.metric\",
          \"points\":[[$currenttime, 20]],
          \"type\":\"gauge\",
          \"host\":\"users_registered\",
          \"tags\":[\"registered\"]}
        ]
    }" \
'https://app.datadoghq.com/api/v1/series?api_key=89f8627f52dd67c483a94ccc78dfa3a6'
