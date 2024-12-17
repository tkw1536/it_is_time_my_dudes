FROM alpine

RUN apk add --no-cache espeak ffmpeg bash bc gawk

# add the data file and the days script
ADD original.mp4 /original.mp4 
ADD dudes.sh /dudes.sh
