import 'dart:math';

/// AI Chat Service — Simulates Haven's AI Persona.
///
/// Implements the AI pipeline (mock version for MVP):
/// Safety → Emotion → Context → Response
///
/// Follows Haven AI Persona strictly:
/// - 温和的心理支持陪伴者
/// - 先理解 → 后探索 → 给选择 → 不强迫
/// - No: 诊断、说教、夸张承诺
///
/// Will be replaced with real LLM API when backend is ready.
class AIChatService {
  final Random _random = Random();

  /// Warm opening messages for first-time chat.
  static const List<String> _greetings = [
    '嗨，很高兴见到你。\n\n这里是一个可以安心说话的地方，你想聊点什么都可以。',
    '你好呀。\n\n不用有压力，说什么都行，或者不说也行。我在这里。',
    '欢迎你来。\n\n今天感觉怎么样？不管是什么感受，都没有对错。',
  ];

  /// Active listening / validation responses.
  static const List<List<String>> _empatheticResponses = [
    [
      '我听到了。谢谢你愿意说出来。',
      '听起来这对你来说很重要。',
      '我能感受到你在很认真地对待这件事。',
      '谢谢你信任我，把这些告诉我。',
    ],
    [
      '嗯，我明白。',
      '这种感觉很真实。',
      '你描述得很清楚，我能理解。',
    ],
    [
      '这不是小事。',
      '你有权利这样感受。',
      '很多人都会有类似的感觉。',
    ],
  ];

  /// Gentle exploration prompts.
  static const List<String> _explorationPrompts = [
    '想多说说吗？',
    '这种感觉是从什么时候开始的？',
    '你希望我帮你梳理一下吗？',
    '如果需要的话，我们可以一起做一个呼吸练习。',
    '你觉得现在最需要的是什么？',
  ];

  /// Gentle closing / offering choices.
  static const List<String> _offeringChoices = [
    '如果你愿意，我们可以：\n\n• 继续聊聊这件事\n• 做一个简单的呼吸练习\n• 写一写你的感受\n\n或者，只是安静地待一会儿也可以。',
    '你现在想做什么呢？\n\n• 继续聊下去\n• 换个话题\n• 试试一个小练习\n• 今天就先到这里\n\n没有哪个选择更好，选你需要的。',
  ];

  /// Crisis detection keywords — response elevates to safety.
  static const List<String> _crisisKeywords = [
    '不想活了',
    '自杀',
    '结束生命',
    '自残',
    '伤害自己',
    '活不下去',
    '绝望',
    '没意义',
    '死',
  ];

  /// Generate a greeting for the chat opening.
  String getRandomGreeting() {
    return _greetings[_random.nextInt(_greetings.length)];
  }

  /// Generate an AI response based on user input.
  ///
  /// Simulates the pipeline: Safety → Emotion → Context → Response.
  Future<String> generateResponse(String userInput) async {
    // Simulate network delay (realistic UX for MVP)
    await Future.delayed(const Duration(milliseconds: 800 + 1200));

    final input = userInput.trim().toLowerCase();

    // Layer 1 — Safety check
    if (_detectCrisis(input)) {
      return _generateSafetyResponse();
    }

    // Layer 2 — Emotion understanding (simple keyword matching for MVP)
    final emotion = _detectEmotion(input);

    // Layer 3 + 4 — Contextual response with persona
    return _buildPersonaResponse(input, emotion);
  }

  /// Check for crisis keywords.
  bool _detectCrisis(String input) {
    return _crisisKeywords.any((kw) => input.contains(kw));
  }

  /// Generate a safe, redirecting response for crisis situations.
  String _generateSafetyResponse() {
    return '我听到了，谢谢你愿意告诉我。\n\n我想让你知道，你现在的感受是重要的，也值得被认真对待。\n\n但是我不能假装我能够处理这么深的问题。如果你现在感到非常难受，请考虑联系：\n\n• 全国心理援助热线：400-161-9995\n• 生命热线：400-821-1215\n\n你并不孤单。';
  }

  /// Simple emotion detection.
  String _detectEmotion(String input) {
    if (input.contains('难过') ||
        input.contains('伤心') ||
        input.contains('哭') ||
        input.contains('低落') ||
        input.contains('抑郁') ||
        input.contains('糟糕')) {
      return 'sad';
    }
    if (input.contains('焦虑') ||
        input.contains('担心') ||
        input.contains('害怕') ||
        input.contains('紧张') ||
        input.contains('不安')) {
      return 'anxious';
    }
    if (input.contains('生气') ||
        input.contains('愤怒') ||
        input.contains('烦') ||
        input.contains('讨厌')) {
      return 'angry';
    }
    if (input.contains('累') ||
        input.contains('疲惫') ||
        input.contains('困') ||
        input.contains('没力气')) {
      return 'tired';
    }
    if (input.contains('开心') ||
        input.contains('高兴') ||
        input.contains('好') ||
        input.contains('不错')) {
      return 'happy';
    }
    return 'neutral';
  }

  /// Build a persona-appropriate response.
  String _buildPersonaResponse(
    String input,
    String emotion,
  ) {
    // Step 1 — Validate / Acknowledge (先理解)
    final validation =
        _empatheticResponses[_random.nextInt(_empatheticResponses.length)];
    final validate = validation[_random.nextInt(validation.length)];

    // Step 2 — Contextual acknowledgment for specific emotions
    final acknowledge = switch (emotion) {
      'sad' => '我能感受到你现在有些难过。',
      'anxious' => '焦虑的感觉确实很不舒服，我能理解。',
      'angry' => '生气是正常的，你不需要为这个感觉道歉。',
      'tired' => '累的时候确实会让人感觉很无力。',
      'happy' => '很高兴你愿意分享这个。',
      'neutral' => '',
    };

    // Step 3 — Gentle exploration (后探索)
    final explore =
        _explorationPrompts[_random.nextInt(_explorationPrompts.length)];

    // Step 4 — Offer choices at appropriate moments
    final offerChoices = _random.nextDouble() > 0.55;

    // Build response
    final buffer = StringBuffer();
    if (acknowledge.isNotEmpty) {
      buffer.writeln(acknowledge);
      buffer.writeln();
    }
    buffer.writeln(validate);

    if (_random.nextDouble() > 0.4) {
      buffer.writeln();
      buffer.write(explore);
    }

    if (offerChoices) {
      buffer.writeln();
      buffer.writeln();
      buffer.write(_offeringChoices[_random.nextInt(_offeringChoices.length)]);
    }

    return buffer.toString().trim();
  }
}

// ============================================
// Real LLM API service (future implementation)
// ============================================
//
// class RealAIChatService implements AIChatService {
//   final Dio _dio;
//
//   RealAIChatService(this._dio);
//
//   @override
//   Future<String> generateResponse(String userInput) async {
//     final response = await _dio.post(
//       '/api/v1/chat',
//       data: {'content': userInput},
//     );
//     return response.data['content'] as String;
//   }
// }
