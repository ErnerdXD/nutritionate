import 'package:flutter/material.dart';

import '../models/food_product.dart';
import '../services/gemini_coach_client.dart';
import '../services/nutrition_coach.dart';
import '../services/scan_history_store.dart';

class NutritionAssistantScreen extends StatefulWidget {
  const NutritionAssistantScreen({super.key, this.product});

  final FoodProduct? product;

  @override
  State<NutritionAssistantScreen> createState() =>
      _NutritionAssistantScreenState();
}

class _Message {
  const _Message(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _NutritionAssistantScreenState extends State<NutritionAssistantScreen> {
  final _controller = TextEditingController();
  final _geminiCoach = GeminiCoachClient();
  final _messages = <_Message>[];
  bool _isSending = false;
  NutritionGoal _goal = NutritionGoal.balanced;
  FoodProduct? _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _messages.add(
      _Message(
        widget.product == null
            ? 'Hi! I am checking your recent scans for product context. You can also ask a general nutrition question.'
            : 'Hi! I can explain ${widget.product!.name} using its recorded nutrition values. What would you like to know?',
        false,
      ),
    );
    if (widget.product == null) _loadLatestProduct();
  }

  Future<void> _loadLatestProduct() async {
    final history = await ScanHistoryStore().getAll();
    if (!mounted || history.isEmpty) return;
    setState(() {
      _product = history.first.product;
      _messages.add(
        _Message(
          'I found your latest scan: ${_product!.name}. I will use its recorded nutrition values for your questions.',
          false,
        ),
      );
    });
  }

  Future<void> _ask([String? suggestion]) async {
    final question = (suggestion ?? _controller.text).trim();
    if (question.isEmpty || _isSending) return;
    setState(() {
      _messages.add(_Message(question, true));
      _controller.clear();
      _isSending = true;
    });
    try {
      final product = _product;
      final recentConversation = _messages
          .skip(_messages.length > 6 ? _messages.length - 6 : 0)
          .map(
            (message) => {
              'role': message.fromUser ? 'user' : 'assistant',
              'text': message.text.length > 600
                  ? message.text.substring(0, 600)
                  : message.text,
            },
          )
          .toList();
      final answer = _isGreeting(question)
          ? product == null
                ? 'Hello! Ask me a general nutrition question, or scan a product so I can explain its label.'
                : 'Hello! I can help explain ${product.name}. Ask me about one serving, the whole package, sugar, protein, salt, calories, or ingredients.'
          : await _geminiCoach.answer(
              question: question,
              goal: _goal,
              product: product,
              recentConversation: recentConversation,
            );
      if (!mounted) return;
      setState(() => _messages.add(_Message(answer, false)));
    } on GeminiCoachException catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(_Message(error.message, false)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _isGreeting(String question) {
    final normalized = question
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    return const {
      'hi',
      'hello',
      'hey',
      'hi there',
      'hello there',
      'hey there',
      'good morning',
      'good afternoon',
      'good evening',
    }.contains(normalized);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Assistant')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gemini assistant • product data goes through your backend',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<NutritionGoal>(
                  initialValue: _goal,
                  decoration: const InputDecoration(
                    labelText: 'My current goal',
                    border: OutlineInputBorder(),
                  ),
                  items: NutritionGoal.values
                      .map(
                        (goal) => DropdownMenuItem(
                          value: goal,
                          child: Text(goal.label),
                        ),
                      )
                      .toList(),
                  onChanged: (goal) {
                    if (goal != null) setState(() => _goal = goal);
                  },
                ),
              ],
            ),
          ),
          if (_product != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                'Discussing: ${_product!.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          if (_product != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _suggestion('Is this healthy?'),
                  _suggestion('What is in one serving?'),
                  _suggestion('What about the whole package?'),
                  _suggestion('Is it allergy-safe?'),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: message.fromUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _ask(),
                    maxLength: 300,
                    decoration: const InputDecoration(
                      hintText: 'Ask about this food…',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: _isSending ? null : _ask,
                  icon: _isSending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'General guidance only. For allergies, medical conditions, pregnancy, or treatment decisions, use the package label and a qualified clinician.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(text), onPressed: () => _ask(text)),
    );
  }
}
