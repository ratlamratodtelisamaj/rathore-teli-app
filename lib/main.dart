import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// IMPORTANT:
/// 1. Firebase Console में Authentication > Email/Password चालू करें।
/// 2. Firestore Database बनाएं (test mode शुरू में ठीक है)।
/// 3. android/app में google-services.json डालें।
/// 4. अपने यूज़र डॉक्यूमेंट में isAdmin: true सेट करें तो एडमिन पैनल दिखेगा।

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RathoreTeliApp());
}

const Color kSaffron = Color(0xFFE65100);

class RathoreTeliApp extends StatelessWidget {
  const RathoreTeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'राठौड़ तेली समाज रतलाम',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kSaffron),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kSaffron,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}

// -------------------- AUTH --------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();
    if (email.isEmpty || pass.length < 6) {
      _toast('ईमेल और कम से कम 6 अक्षर का पासवर्ड डालें');
      return;
    }
    setState(() => loading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? e.code);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('राठौड़ तेली समाज रतलाम')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.favorite, size: 72, color: kSaffron),
              const SizedBox(height: 8),
              Text(
                isLogin ? 'सदस्य लॉगिन' : 'नया खाता बनाएं',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ईमेल',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'पासवर्ड',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kSaffron, foregroundColor: Colors.white),
                        onPressed: _submit,
                        child: Text(isLogin ? 'लॉगिन करें' : 'रजिस्टर करें'),
                      ),
                    ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'नया खाता बनाएं' : 'पहले से खाता है? लॉगिन'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- HOME --------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.data()?['isAdmin'] == true && mounted) {
      setState(() => isAdmin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('राठौड़ तेली समाज रतलाम'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'एडमिन पैनल',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'वर (लड़के)'),
            Tab(text: 'वधू (लड़कियां)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          ProfileListView(gender: 'वर'),
          ProfileListView(gender: 'वधू'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSaffron,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProfileScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('बायोडाटा जोड़ें'),
      ),
    );
  }
}

// -------------------- LIST + FILTERS --------------------
class ProfileListView extends StatefulWidget {
  final String gender;
  const ProfileListView({super.key, required this.gender});

  @override
  State<ProfileListView> createState() => _ProfileListViewState();
}

class _ProfileListViewState extends State<ProfileListView> {
  final _gotra = TextEditingController();
  final _city = TextEditingController();
  final _education = TextEditingController();
  final _minAge = TextEditingController();
  final _maxAge = TextEditingController();

  bool _match(Map<String, dynamic> data) {
    bool has(String q, dynamic v) =>
        q.trim().isEmpty || (v ?? '').toString().toLowerCase().contains(q.trim().toLowerCase());
    final age = int.tryParse('${data['age'] ?? ''}') ?? 0;
    final minA = int.tryParse(_minAge.text) ?? 0;
    final maxA = int.tryParse(_maxAge.text) ?? 99;
    return has(_gotra.text, data['gotra']) &&
        has(_city.text, data['city']) &&
        has(_education.text, data['education']) &&
        (age == 0 || (age >= minA && age <= maxA));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gotra,
                      decoration: const InputDecoration(
                        labelText: 'गोत्र',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'शहर',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _education,
                      decoration: const InputDecoration(
                        labelText: 'शिक्षा',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _minAge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'उम्र से',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _maxAge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'तक',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('profiles')
                .where('gender', isEqualTo: widget.gender)
                .where('status', isEqualTo: 'Approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('एरर: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs.where((d) {
                return _match(d.data() as Map<String, dynamic>);
              }).toList();
              if (docs.isEmpty) {
                return Center(child: Text('${widget.gender} की कोई प्रोफाइल फिल्टर में नहीं मिली।'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString();
                  final photo = (data['photoUrl'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFE0B2),
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isNotEmpty ? null : Text(name.isNotEmpty ? name[0] : '?'),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'गोत्र: ${data['gotra'] ?? '-'} | शिक्षा: ${data['education'] ?? '-'}\n'
                        'शहर: ${data['city'] ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: Text('${data['age'] ?? ''} वर्ष'),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(name),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (photo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Image.network(photo, height: 160, fit: BoxFit.cover),
                                  ),
                                Text('स्वयं का गोत्र: ${data['gotra'] ?? '-'}'),
                                Text('ननिहाल गोत्र: ${data['nanihalGotra'] ?? '-'}'),
                                Text('उम्र: ${data['age'] ?? '-'} वर्ष'),
                                Text('शिक्षा: ${data['education'] ?? '-'}'),
                                Text('व्यवसाय: ${data['occupation'] ?? '-'}'),
                                Text('शहर: ${data['city'] ?? '-'}'),
                                const Divider(),
                                Text(
                                  'संपर्क: ${data['phone'] ?? '-'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('बंद'),
                            ),
                            if ((data['phone'] ?? '').toString().isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  launchUrl(Uri.parse('tel:${data['phone']}'));
                                },
                                child: const Text('कॉल करें'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------- ADD PROFILE --------------------
class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _name = TextEditingController();
  final _gotra = TextEditingController();
  final _nanihal = TextEditingController();
  final _age = TextEditingController();
  final _education = TextEditingController();
  final _occupation = TextEditingController();
  final _city = TextEditingController(text: 'रतलाम');
  final _phone = TextEditingController();
  String _gender = 'वर';
  bool saving = false;
  File? _photo;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('नाम और मोबाइल नंबर ज़रूरी हैं')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      String photoUrl = '';
      if (_photo != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
        final ref = FirebaseStorage.instance
            .ref()
            .child('profiles')
            .child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_photo!);
        photoUrl = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('profiles').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'name': _name.text.trim(),
        'gender': _gender,
        'gotra': _gotra.text.trim(),
        'nanihalGotra': _nanihal.text.trim(),
        'age': _age.text.trim(),
        'education': _education.text.trim(),
        'occupation': _occupation.text.trim(),
        'city': _city.text.trim(),
        'phone': _phone.text.trim(),
        'photoUrl': photoUrl,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('बायोडाटा भेज दिया गया। एडमिन अप्रूवल के बाद दिखेगा।')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('नया बायोडाटा')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final x = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (x != null) setState(() => _photo = File(x.path));
              },
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFFFE0B2),
                backgroundImage: _photo != null ? FileImage(_photo!) : null,
                child: _photo == null
                    ? const Icon(Icons.camera_alt, size: 36, color: kSaffron)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text('फोटो चुनें (गैलरी)'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'प्रत्याशी', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'वर', child: Text('वर (लड़का)')),
                DropdownMenuItem(value: 'वधू', child: Text('वधू (लड़की)')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'वर'),
            ),
            const SizedBox(height: 12),
            _field(_name, 'पूरा नाम'),
            _field(_gotra, 'स्वयं का गोत्र'),
            _field(_nanihal, 'ननिहाल का गोत्र'),
            _field(_age, 'उम्र', type: TextInputType.number),
            _field(_education, 'शिक्षा'),
            _field(_occupation, 'व्यवसाय / नौकरी'),
            _field(_city, 'शहर / पता'),
            _field(_phone, 'मोबाइल नंबर', type: TextInputType.phone),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kSaffron, foregroundColor: Colors.white),
                onPressed: saving ? null : _save,
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('जमा करें'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ADMIN --------------------
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('एडमिन पैनल')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profiles')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('कोई पेंडिंग बायोडाटा नहीं है।'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['name']} (${data['gender']})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('गोत्र: ${data['gotra']} | उम्र: ${data['age']} | मोबाइल: ${data['phone']}'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => doc.reference.delete(),
                            child: const Text('रिजेक्ट', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(
                            onPressed: () => doc.reference.update({'status': 'Approved'}),
                            child: const Text('स्वीकार करें'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
