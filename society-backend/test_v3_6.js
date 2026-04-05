const axios = require('axios');

const API_URL = 'http://localhost:3000/ai';
const AUTH_TOKEN = 'test_token'; // Mock token for dev

// Tiny 1x1 transparent PNG Base64
const TINY_PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

async function runTests() {
  console.log('🚀 Starting V3.6 Integration Tests...\n');

  try {
    // 1. Test Multi-modal Chat
    console.log('🧪 Testing Multi-modal Chat...');
    const chatRes = await axios.post(`${API_URL}/chat`, {
      message: 'What is in this image?',
      base64Image: TINY_PNG
    }, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✅ Chat Response:', chatRes.data.reply || 'Success (Draft/Text)');

    // 2. Test Receipt Extraction
    console.log('\n🧪 Testing Receipt Extraction...');
    const recRes = await axios.post(`${API_URL}/extract-receipt`, {
      base64Image: TINY_PNG
    }, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✅ Extraction Result:', recRes.data);

  } catch (error) {
    console.error('❌ Test Failed:', error.response?.data || error.message);
  }
}

runTests();
