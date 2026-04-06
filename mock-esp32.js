const http = require('http');

const liveData = {
  ts: 0, node_id: "FL-001", moisture_raw: 1543, moisture_pct: 65.2,
  water_raw: 2100, water_pct: 44.5, moisture_stress: 0, water_stress: 0,
  cs: 0.0, cv: 0.72, ccombined: 0.43, alert: false,
  detection_class: "Tomato_healthy", detection_conf: 0.72,
  cycle_id: "FL-001-00001-00"
};

http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (req.url === '/api/status')
    return res.end(JSON.stringify({node_id:"FL-001",mode:"MOCK",uptime_s:3600,free_heap:200000,wifi_clients:1}));
  if (req.url.startsWith('/api/live')) {
    liveData.ts = Math.floor(Date.now()/1000);
    liveData.moisture_pct = parseFloat((40 + Math.sin(Date.now()/10000) * 30).toFixed(1));
    liveData.ccombined = parseFloat((0.3 + Math.random()*0.4).toFixed(2));
    liveData.cycle_id = "FL-001-" + String(Math.floor(Date.now()/5000)).padStart(5,'0') + "-00";
    return res.end(JSON.stringify(liveData));
  }
  if (req.url.startsWith('/api/logs'))
    return res.end(JSON.stringify({count:0,logs:[]}));
  if (req.url === '/api/settings' && req.method === 'GET')
    return res.end(JSON.stringify({w1:0.6,w2:0.4,theta:0.5,crop_type:"tomato"}));
  if (req.url === '/api/settings' && req.method === 'POST')
    return res.end(JSON.stringify({ok:true}));
  res.end('{}');
}).listen(80, '0.0.0.0', function() { console.log('Mock ESP32 running on port 80'); });