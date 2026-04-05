const https = require('http'); // Using http for localhost

const TINY_PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

function post(path, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'Authorization': 'Bearer test_token'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => resolve({ statusCode: res.statusCode, data: JSON.parse(body) }));
    });

    req.on('error', (e) => reject(e));
    req.write(postData);
    req.end();
  });
}

async function runTests() {
  console.log('🚀 Starting V3.6 Integration Tests (Native)...\n');

  try {
    // 1. Test Multi-modal Chat
    console.log('🧪 Testing Multi-modal Chat...');
    const chatRes = await post('/ai/chat', {
      message: 'What is this?',
      base64Image: TINY_PNG
    });
    console.log('✅ Chat Response:', chatRes.data.reply || 'Success');

    // 2. Test Receipt Extraction
    console.log('\n🧪 Testing Receipt Extraction...');
    const recRes = await post('/ai/extract-receipt', {
      base64Image: TINY_PNG
    });
    console.log('✅ Extraction Result:', recRes.data);

  } catch (error) {
    console.error('❌ Test Failed:', error.message);
  }
}

runTests();
