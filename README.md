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
The [`Mjpeg` widget](https://pub.dev/documentation/flutter_mjpeg/latest/flutter_mjpeg/Mjpeg-class.html) expects a `stream` parameter with the HTTP URL of the MJPEG stream and can handle the following additional parameters:

Parameter | Description
--- | ---
`isLive` | Whether or not the stream should be loaded continuously
`timeout` | HTTP Timeout when fetching the MJPEG stream
`width` | Force width
`height` | Force height
`error` | Error builder used when an error occurred
`loading` | Loading builder used until first frame arrived
`fit` | The `boxFit` of the image
`headers` | A map of headers to send in the HTTP request
`httpClient` | Used to give a custom httpClient, for example `DigestAuthClient()` from [http_auth](https://pub.dev/packages/http_auth). Defaults to `Client()` from [http](https://pub.dev/packages/http).
`preprocessor` | Used to apply preprocessing to each frame of the MJPEG stream before it is sent to [Image](https://api.flutter.dev/flutter/widgets/Image-class.html) for rendering. Defaults to `MjpegPreprocessor()`, which passes each frame without modification. 
