# OpenCode Zen Free Models API Documentation

OpenCode Zen is a curated gateway of tested and verified AI models optimized specifically for coding and general-purpose reasoning agents. In addition to commercial models, OpenCode Zen provides several **free models** served through an OpenAI-compatible API without requiring any registration or API keys.

This document details the available free models, API endpoints, and integration code snippets to help you use them in other projects and languages.

---

## 🚀 API Endpoint

* **Base URL:** `https://opencode.ai/zen/v1`
* **Chat Completions Endpoint:** `https://opencode.ai/zen/v1/chat/completions`
* **Authentication:** No API key required for free models. You can pass an empty or dummy Bearer token (`Bearer empty` or `Bearer free`).

---

## 🤖 Available Free Models

The following high-quality models are served completely free through OpenCode Zen:

| Model ID | Best For | Description | Cost |
| :--- | :--- | :--- | :--- |
| **`big-pickle`** | General coding & reasoning | Default general-purpose coding and reasoning stealth model. Extremely fast. | **Free** |
| **`deepseek-v4-flash-free`** | Fast reasoning & general chat | DeepSeek's fast reasoning and conversational model, highly optimized. | **Free** |
| **`mimo-v2.5-free`** | Large codebases & refactoring | Xiaomi's updated coding model, handles long context and multi-file changes. | **Free** |
| **`hy3-free`** | Creative & complex tasks | Advanced reasoning model for creative problem-solving and coding. | **Free** |
| **`nemotron-3-ultra-free`** | Super fast completions | NVIDIA's high-speed reasoning model, optimized for low-latency completions. | **Free** |
| **`north-mini-code-free`** | Compact coding assistant | Ultra-fast, lightweight coding model optimized for code generation and debugging. | **Free** |

---

## 🛠️ Multi-Language Integration Snippets

Since OpenCode Zen's API is **100% OpenAI-compatible**, you can use any standard OpenAI client library or raw HTTP requests.

### 1. 🐚 cURL (HTTP POST)
For quick testing directly from your terminal:

```bash
curl -X POST https://opencode.ai/zen/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer free" \
  -d '{
    "model": "big-pickle",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain binary search in 2 sentences."}
    ],
    "stream": false
  }'
```

### 2. 🐍 Python
Using the official `openai` SDK:

```python
from openai import OpenAI

# Initialize standard OpenAI client pointing to OpenCode Zen
client = OpenAI(
    base_url="https://opencode.ai/zen/v1",
    api_key="free"  # No key required, any dummy value works
)

response = client.chat.completions.create(
    model="big-pickle",
    messages=[
        {"role": "system", "content": "You are a helpful general-purpose AI."},
        {"role": "user", "content": "Brainstorm 3 project ideas using Flutter."}
    ],
    stream=True
)

for chunk in response:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

### 3. 🟨 TypeScript / JavaScript (Node.js)
Using the official `@openai/api` package:

```typescript
import OpenAI from "openai";

const openai = new OpenAI({
  baseURL: "https://opencode.ai/zen/v1",
  apiKey: "free"
});

async function main() {
  const stream = await openai.chat.completions.create({
    model: "big-pickle",
    messages: [
      { role: "system", content: "You are a polyvalent AI assistant." },
      { role: "user", content: "Write a short poem about coding." }
    ],
    stream: true,
  });

  for await (const chunk of stream) {
    process.stdout.write(chunk.choices[0]?.delta?.content || "");
  }
  console.log();
}

main();
```

### 4. 🎯 Dart / Flutter
Using Dart's built-in `HttpClient` for standard zero-dependency streaming:

```dart
import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final client = HttpClient();
  final url = Uri.parse('https://opencode.ai/zen/v1/chat/completions');

  final request = await client.postUrl(url);
  request.headers.contentType = ContentType.json;

  final payload = {
    'model': 'big-pickle',
    'messages': [
      {'role': 'user', 'content': 'Hello from Dart!'}
    ],
    'stream': true
  };

  request.write(jsonEncode(payload));
  final response = await request.close();

  if (response.statusCode == 200) {
    final stream = response.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final dataStr = line.substring(6).trim();
        if (dataStr == '[DONE]') continue;
        try {
          final data = jsonDecode(dataStr);
          final text = data['choices'][0]['delta']['content'] ?? '';
          stdout.write(text);
        } catch (_) {}
      }
    }
  } else {
    print('Failed with status: ${response.statusCode}');
  }
  client.close();
}
```

---

## 🌟 Capabilities & Best Practices

1. **Multimodal Inputs (Images):**
   You can send image data to OpenCode Zen free models using standard OpenAI multimodal base64 image URL formatting:
   ```json
   {
     "role": "user",
     "content": [
       { "type": "text", "text": "What is in this image?" },
       { "type": "image_url", "image_url": { "url": "data:image/png;base64,iVBORw0KGgo..." } }
     ]
   }
   ```
2. **Streaming:** Always set `"stream": true` when integrating into client applications (like chat interfaces) to get real-time token feedback and avoid perceived latency.
3. **Graceful Fallbacks:** To protect your application, always implement a local mock/fallback generator if the remote service experiences rate-limiting, downtime, or network failures.
