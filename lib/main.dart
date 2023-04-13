import 'dart:convert';

import 'package:chatgpt/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'model.dart';

void main(List<String> args) {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyHome(),
    );
  }
}

const bacgroundColor = Color(0xff343541);
const botBackgroundColor = Color(0xff444654);

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  late bool isLoading;
  final TextEditingController _textEditingController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = false;
  }

  Future<String> generateResponse(String prompt) async {
    const apiKey = apiSecretKey;
    var url = Uri.https("api.openai.com", "/v1/completions");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application.json',
        'Authorization': 'Bearer $apiKey'
      },
      body: jsonEncode(
        {
          'model': 'text-davinci-003',
          'prompt': prompt,
          'temperature': 0,
          'max_token': 2000,
          'top_p': 1,
          'frequency_penalty': 0.0,
          'presence_penalty': 0.0,
        },
      ),
    );
    Map<String, dynamic> newresponse = jsonDecode(response.body);
    return newresponse['choices'][0]['text'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: botBackgroundColor,
        centerTitle: true,
        title: const Text(
          'OpenAI Chatgpt',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: bacgroundColor,
      body: Column(
        children: [
          Expanded(
            child: _buildList(),
          ),
          Visibility(
            visible: isLoading,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              _buildInput(),
              _buildSubmit(),
            ],
          ),
        ],
      ),
    );
  }

  Expanded _buildInput() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          controller: _textEditingController,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            fillColor: Colors.grey.shade900,
            filled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmit() {
    return Visibility(
      visible: !isLoading,
      child: IconButton(
          onPressed: () {
            setState(() {
              _messages.add(ChatMessage(
                  text: _textEditingController.text,
                  chatMessageType: ChatMessageType.user));
              isLoading = true;
            });
            var input = _textEditingController.text;
            _textEditingController.clear();
            Future.delayed(const Duration(milliseconds: 50))
                .then((value) => _scrollDown());

            generateResponse(input).then((value) {
              setState(() {
                isLoading = false;
                _messages.add(ChatMessage(
                    text: value, chatMessageType: ChatMessageType.bot));
              });
            });
            _textEditingController.clear();
            Future.delayed(Duration(milliseconds: 50))
                .then((value) => _scrollDown());
          },
          icon: const Icon(Icons.send_rounded)),
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  ListView _buildList() {
    return ListView.builder(
      itemCount: _messages.length,
      controller: _scrollController,
      itemBuilder: (context, index) {
        var message = _messages[index];
        return ChatMessageWidget(
          text: message.text,
          chatMessageType: message.chatMessageType,
        );
      },
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String text;
  final ChatMessageType chatMessageType;
  const ChatMessageWidget(
      {super.key, required this.text, required this.chatMessageType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      color: chatMessageType == ChatMessageType.bot
          ? botBackgroundColor
          : bacgroundColor,
      child: Row(
        children: [
          chatMessageType == ChatMessageType.bot
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(16, 163, 127, 1),
                    child: Image.asset(
                      'lib/assets/images/bot.png',
                      scale: 1.5,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(
                    right: 16,
                  ),
                  child: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ))
        ],
      ),
    );
  }
}
