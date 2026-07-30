import 'dart:async';

enum ListeningState { idle, listening, processing, speaking }

class VoiceService {
  final StreamController<String> _commandStream = StreamController<String>.broadcast();
  final StreamController<ListeningState> _stateStream = StreamController<ListeningState>.broadcast();

  Stream<String> get commandStream => _commandStream.stream;
  Stream<ListeningState> get stateStream => _stateStream.stream;
  ListeningState _state = ListeningState.idle;

  ListeningState get state => _state;

  Future<void> startListening() async {
    _state = ListeningState.listening;
    _stateStream.add(_state);
  }

  Future<void> stopListening() async {
    _state = ListeningState.idle;
    _stateStream.add(_state);
  }

  void processCommand(String text) {
    _state = ListeningState.processing;
    _stateStream.add(_state);
    _commandStream.add(text.toLowerCase());
    _state = ListeningState.idle;
    _stateStream.add(_state);
  }

  void speakResponse(String response) {
    _state = ListeningState.speaking;
    _stateStream.add(_state);
    Future.delayed(const Duration(seconds: 2), () {
      _state = ListeningState.idle;
      _stateStream.add(_state);
    });
  }

  void dispose() {
    _commandStream.close();
    _stateStream.close();
  }
}
