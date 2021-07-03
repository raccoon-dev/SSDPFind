const SSDP_SIG  = 'RacDiscovery/1.0';
const SSDP_UDN  = 'a178702a-325c-4e69-ab44-0f8bc85d174c';
const SSDP_USN  = 'urn:schemas-upnp-org:RacTool:control:1';
const SSDP_PORT = 1900;

var PORT = 65500;
if (process.argv.length >= 4) {
  ADDR = process.argv[3];
}

var ADDR = require('ip').address();
if (process.argv.length >= 3) {
  ADDR = process.argv[2];
}


var Server = require('node-ssdp').Server
  , server = new Server({
      udn: SSDP_UDN,
      location: ADDR + ':' + PORT,
      sourcePort: SSDP_PORT,
      ssdpSig: SSDP_SIG,
      ssdpPort: SSDP_PORT,
      ssdpTtl: 4,
  });

//server._logger.enabled = true;

server.addUSN(SSDP_USN);

// start the server
server.start();

process.on('exit', function(){
  server.stop() // advertise shutting down and stop listening
});
