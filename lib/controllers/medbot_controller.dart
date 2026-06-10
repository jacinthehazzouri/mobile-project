import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../utils/config.dart';

// ─── MedBot Controller ────────────────────────────────────────
// Handles all Gemini API logic and chat history management
class MedBotController extends ChangeNotifier {

  // Chat history — list of all messages in the conversation
  final List<ChatMessage> messages = [];

  // Loading state — true while waiting for Gemini response
  bool isLoading = false;

  // Error message — shown if API call fails
  String? errorMessage;

  // ── System prompt ─────────────────────────────────────────
  // This tells Gemini how to behave as MedBot
  static const String _systemPrompt = '''
You are MedBot, a helpful and friendly medical assistant 
built into the MedBox smart medicine reminder app.

Your role is to:
- Help patients understand their medications (what they do, side effects, interactions)
- Advise on what to do if a dose is missed
- Answer general medicine and health questions clearly and simply
- Support caregivers with questions about managing patient medication
- Remind users to always consult their doctor for serious medical decisions

Rules:
- Keep answers short, clear and easy to understand (max 3-4 sentences)
- Never diagnose diseases or replace a doctor
- Always add a reminder to consult a healthcare professional for serious concerns
- Be empathetic and supportive — many users are elderly or managing chronic conditions
- If asked about something unrelated to medicine or health, politely redirect to medicine topics
- Use simple language, avoid complex medical jargon

App context: You are part of the MedBox IoT system which uses a 
smart pill box with sensors to track whether patients take 
their medicine on time. The box has a buzzer, LEDs, and a 
distance sensor that detects when the lid is opened.
''';

  // ── Gemini API URL ────────────────────────────────────────
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  MedBotController() {
    _addBotMessage(
      "Hi! I'm MedBot 👋 I'm here to help you with questions about your medication. What would you like to know?",
    );
  }

  // ── Send message ──────────────────────────────────────────
  // Called by the view when user taps send
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to chat
    messages.add(ChatMessage(text: text.trim(), isUser: true));
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _callGeminiApi(text.trim());
      _addBotMessage(response);
    } catch (e) {
      print('MedBot error: $e');
      errorMessage = 'Connection error. Please check your internet.';
      _addBotMessage('Sorry, I had trouble connecting. Please try again.');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Call Gemini API ───────────────────────────────────────
  // Builds the request with system prompt + conversation history
  Future<String> _callGeminiApi(String userMessage) async {
    // Build conversation history for context
    // Gemini needs alternating user/model roles
    final List<Map<String, dynamic>> contents = [];

    // Add previous messages as context (last 10 messages max)
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    for (final msg in recentMessages) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }

    // Build request body
    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _systemPrompt}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 300,
      },
    });

    // Call Gemini API
    final response = await http.post(
      Uri.parse('$_apiUrl?key=${AppConfig.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Extract text from response
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  // ── Add bot message helper ────────────────────────────────
  void _addBotMessage(String text) {
    messages.add(ChatMessage(text: text, isUser: false));
    notifyListeners();
  }

  // ── Clear chat ────────────────────────────────────────────
  void clearChat() {
    messages.clear();
    _addBotMessage(
      "Hi! I'm MedBot 👋 I'm here to help you with questions about your medication. What would you like to know?",
    );
    notifyListeners();
  }
}