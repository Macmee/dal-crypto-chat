<p align="center">
  <img src="http://i.imgur.com/70xkcAo.png" alt="Sublime's custom image"/>
</p>

## This is a school project

https://www.youtube.com/watch?v=OroRRxt-LG8&feature=youtu.be

### Setting up the server

The server requires nodejs (5.x.x) to be installed on your machine. Preferably you should be running OS X 10.11, Ubuntu > 12.04, Cent OS, etc.

1. cd into `/server`
2. type `npm install`
3. cd into `/patches/enhanced-promises` and do `npm install` and also cd to `/patches/import-export` and do `npm install`
4. go back to `/server` and type `node index` and the server should now be online

### Setting up the client

You need XCode 7.3 (7D175) for this because Apple changed selector syntax and our group (living on the edge) used this new syntax :)

The client users a small handful of libraries, QRCodeReader, QRCode, PromiseKit and Heimdall. You can install all of these easily with Cocoapods:

1. download and setup cocoapods with `sudo gem install cocoapods`
2. cd to our project root and type `pod install`
3. a file ending in `.xcodeworkspace` should be generated, you must open *this* file to run the project