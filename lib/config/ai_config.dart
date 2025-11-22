class AiConfig {
  final String apiUrl;
  final String defaultModel;
  final String systemPrompt;
  final String eventSystemPrompt;

  AiConfig({
    required this.apiUrl,
    required this.defaultModel,
    required this.systemPrompt,
    required this.eventSystemPrompt,
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      apiUrl: json['api_url'] ?? 'https://chat.2gis.dev/api',
      defaultModel: json['default_model'] ?? 'gpt-4',
      systemPrompt: json['system_prompt'] ?? 'Ты - эксперт по местам отдыха и развлечений. Твоя задача - рекомендовать интересные места на основе предпочтений пользователя. Отвечай кратко и по делу, перечисляя конкретные места с кратким описанием.',
      eventSystemPrompt: json['event_system_prompt'] ?? 'Ты — эксперт по отдыху и развлечениям. Тебе дан список событий (мероприятий) в городе и предпочтения пользователя. Выбери из списка лучшие места для отдыха, которые максимально соответствуют предпочтениям. Для каждого места укажи название, краткое описание и причину выбора. Не придумывай свои места, используй только из списка.',
    );
  }

  factory AiConfig.defaultConfig() {
    return AiConfig(
      apiUrl: 'https://chat.2gis.dev/api',
      defaultModel: 'gpt-4o',
      systemPrompt: 'Ты - эксперт по местам отдыха и развлечений. Твоя задача - рекомендовать интересные места на основе предпочтений пользователя. Отвечай кратко и по делу, перечисляя конкретные места с кратким описанием.',
      eventSystemPrompt: 'Ты — эксперт по отдыху и развлечениям. Тебе дан список событий (мероприятий) в городе и предпочтения пользователя. Выбери из списка лучшие места для отдыха, которые максимально соответствуют предпочтениям. Для каждого места укажи название, краткое описание и причину выбора. Не придумывай свои места, используй только из списка.',
    );
  }
}
