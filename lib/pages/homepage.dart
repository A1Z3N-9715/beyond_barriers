import 'package:bb/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(const LanguageLearningApp());
}

class LanguageLearningApp extends StatelessWidget {
  const LanguageLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond Barriers',
      theme: ThemeData.dark(),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedLanguage = 'English';
  Map<String, int> completedLessonsMap = {'English': 0, 'Hindi': 0, 'Tamil': 0};
  int currentStreak = 0;
  final FlutterTts flutterTts = FlutterTts();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  List<String> languages = ['English', 'Hindi', 'Tamil'];

  final Map<String, List<String>> alphabets = {
    'English': List.generate(26, (i) => String.fromCharCode(65 + i)),
    'Hindi': [
      'अ',
      'आ',
      'इ',
      'ई',
      'उ',
      'ऊ',
      'ऋ',
      'ए',
      'ऐ',
      'ओ',
      'औ',
      'क',
      'ख',
      'ग',
      'घ',
      'ङ',
      'च',
      'छ',
      'ज',
      'झ',
      'ञ',
      'ट',
      'ठ',
      'ड',
      'ढ',
      'ण',
      'त',
      'थ',
      'द',
      'ध',
      'न',
      'प',
      'फ',
      'ब',
      'भ',
      'म',
      'य',
      'र',
      'ल',
      'व',
      'श',
      'ष',
      'स',
      'ह',
      'क्ष',
      'त्र',
      'ज्ञ'
    ],
    'Tamil': [
      'அ',
      'ஆ',
      'இ',
      'ஈ',
      'உ',
      'ஊ',
      'எ',
      'ஏ',
      'ஐ',
      'ஒ',
      'ஓ',
      'ஔ',
      'க',
      'ங',
      'ச',
      'ஞ',
      'ட',
      'ண',
      'த',
      'ந',
      'ப',
      'ம',
      'ய',
      'ர',
      'ல',
      'வ',
      'ஷ',
      'ஸ',
      'ஹ',
      'ள',
      'ழ',
      'ற',
      'ன',
      'ஜ',
      'ஷ',
      'ஸ',
      'ஹ',
    ],
  };

  Map<String, List<String>> greetings = {
    'English': ['Hello', 'Good morning', 'How are you?', 'Good evening', 'Bye'],
    'Hindi': ['नमस्ते', 'सुप्रभात', 'कैसे हो?', 'शुभ संध्या', 'अलविदा'],
    'Tamil': [
      'வணக்கம்',
      'காலை வணக்கம்',
      'நீங்கள் எப்படி?',
      'மாலை வணக்கம்',
      'பிரியாவிடை'
    ],
  };

  Map<String, List<String>> phrases = {
    'English': ['Thank you', 'Please', 'I need help'],
    'Hindi': ['धन्यवाद', 'कृपया', 'मुझे मदद चाहिए'],
    'Tamil': ['நன்றி', 'தயவு செய்து', 'எனக்கு உதவி வேண்டும்'],
  };

  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      loadUserProgress().then((_) {
        updateStreakOnLogin();
      });
    }
  }

  Future<void> loadUserProgress() async {
    try {
      final progressSnap = await dbRef.child('users/$userId/progress').get();
      if (progressSnap.exists) {
        final data = Map<String, dynamic>.from(progressSnap.value as Map);
        setState(() {
          completedLessonsMap = {
            for (var entry in data.entries)
              entry.key: entry.value is int
                  ? entry.value
                  : int.tryParse(entry.value.toString()) ?? 0,
          };
        });
      }

      final streakSnap = await dbRef.child('users/$userId/streak').get();
      if (streakSnap.exists) {
        setState(() {
          currentStreak = streakSnap.value is int
              ? streakSnap.value as int
              : int.tryParse(streakSnap.value.toString()) ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> updateStreakOnLogin() async {
    final now = DateTime.now();
    final userRef = dbRef.child('users/$userId');

    try {
      final lastLoginSnap = await userRef.child('lastLogin').get();
      int newStreak = 1;

      if (lastLoginSnap.exists) {
        DateTime lastLogin =
            DateTime.tryParse(lastLoginSnap.value.toString()) ?? now;
        final difference = now.difference(lastLogin).inHours;

        if (difference < 24) {
          // Same day login, keep streak as is
          newStreak = currentStreak;
        } else if (difference >= 24 && difference < 48) {
          // Consecutive day login, increment streak
          newStreak = currentStreak + 1;
        } else {
          // Missed a day, reset streak
          newStreak = 1;
        }
      }

      setState(() {
        currentStreak = newStreak;
      });

      await userRef.update({
        'streak': currentStreak,
        'lastLogin': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating streak on login: $e');
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage(_getTtsLanguage(selectedLanguage));
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(text);
    await _incrementProgress();
  }

  Future<void> _incrementProgress() async {
    setState(() {
      completedLessonsMap[selectedLanguage] =
          (completedLessonsMap[selectedLanguage] ?? 0) + 1;

      // Increment streak on lesson complete, optional if you want
      // currentStreak++;  // Not needed if streak is for login only
    });

    try {
      await dbRef.child('users/$userId/progress').update({
        selectedLanguage: completedLessonsMap[selectedLanguage],
      });
      await dbRef.child('users/$userId/streak').set(currentStreak);
    } catch (e) {
      debugPrint('Error updating progress/streak: $e');
    }
  }

  String _getTtsLanguage(String lang) {
    switch (lang) {
      case 'Hindi':
        return 'hi-IN';
      case 'Tamil':
        return 'ta-IN';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalAlphabets = alphabets[selectedLanguage]?.length ?? 26;

    double progress =
        (completedLessonsMap[selectedLanguage]! / totalAlphabets).clamp(0, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beyond Barriers'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguage,
              dropdownColor: Colors.black,
              items: languages.map((String lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child:
                      Text(lang, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedLanguage = newValue!;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _logout,
            child: const Text("Logout"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello👋',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Text('Continue your journey to language fluency'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                      'Completion Rate', '${(progress * 100).toInt()}%'),
                  _buildStatCard('Current Streak', '$currentStreak days'),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Start Learning',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: _buildLearningTabs(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningTabs() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Alphabets'),
              Tab(text: 'Numbers'),
              Tab(text: 'Greetings'),
              Tab(text: 'Phrases'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAlphabetsGrid(),
                _buildNumbersGrid(),
                _buildTextList(greetings[selectedLanguage] ?? []),
                _buildTextList(phrases[selectedLanguage] ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetsGrid() {
    List<String> letters = alphabets[selectedLanguage]!;
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        String letter = letters[index];
        return Card(
          color: Colors.deepPurple.shade700,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(letter, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 7),
                SizedBox(
                  height: 30,
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: () => speak(letter),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumbersGrid() {
    List<int> numbers = List.generate(20, (index) => index + 1);
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        int number = numbers[index];
        return Card(
          color: Colors.deepPurple.shade700,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$number', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 7),
                SizedBox(
                  height: 30,
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: () => speak(number.toString()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextList(List<String> texts) {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: texts.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        String text = texts[index];
        return ListTile(
          title: Text(text, style: const TextStyle(fontSize: 18)),
          trailing: IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => speak(text),
          ),
        );
      },
    );
  }
}

// Dummy loading page shown after logout (you can replace this)
class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Loading...")),
    );
  }
}
