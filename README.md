# flutter_mjpeg

Flutter widget to show mjpeg stream from URL

This is a full dart implementation of MJPEG reader. No native involve.

## Usage

```
Mjpeg(
  stream: 'http://192.168.1.24:8080/video.cgi',
)
```

## API

`stream` : URL of the MJPEG stream

`width` : force width

`height` : force height

`error` : error builder used when an error occurred 

`loading` : loading builder used until first frame arrived

`fit` : boxFit of the image
