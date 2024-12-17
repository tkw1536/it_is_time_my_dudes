# It Is Time My Dudes

This is a script to automatically replace the Wednesday.

This repo doesn't contain the data file. 
The data file is [the original](https://www.youtube.com/watch?v=du-TY1GUFGk), and should be named `original.mp4`. 

To run it:

```bash
# build a docker image
docker build -t it_is_time_my_dudes .

# generate a meme
docker run -i --rm --read-only --mount type=tmpfs,destination=/tmp it_is_time_my_dudes bash /dudes.sh "Meme Time" > meme.mp4
```
