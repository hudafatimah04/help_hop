/*
==============================================
HelpHop - Secure Disaster Response App
==============================================

SETUP INSTRUCTIONS:
1. Create a new Flutter project:
   flutter create helphop

2. Replace lib/main.dart with this entire file

3. Add dependencies to pubspec.yaml:
   dependencies:
     flutter:
       sdk: flutter
     shared_preferences: ^2.2.2
     intl: ^0.18.1

4. Get dependencies:
   flutter pub get

5. Run the app:
   flutter run

Built with ❤️ by Huda Fatimah, Manyashree S, 
Devisri Harshini Baramal, and G. Roweena Siphora
DTL Project: Secure Mesh-based Disaster Response App
==============================================
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:help_hop/utils/location_helper.dart';

import 'package:help_hop/ble/sos_advertiser.dart';
import 'package:help_hop/ble/sos_scanner.dart';
import 'package:help_hop/ble/sos_packet.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


// Global advertiser ONLY
final SosAdvertiser advertiser = SosAdvertiser();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   print("🚀 MAIN STARTED");
  runApp(const HelpHopApp());
}



// Main App Widget
class HelpHopApp extends StatelessWidget {
  const HelpHopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpHop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// App Initializer - checks if onboarding is complete

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isOnboarded = false;
  String? _userRole; // 'victim' or 'rescuer'

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role'); // 'victim' or 'rescuer'
    final onboarded = prefs.getBool('onboarding_complete') ?? false;

    setState(() {
      _userRole = role;
      _isOnboarded = onboarded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // First time: no role chosen yet
    if (_userRole == null) {
      return const RoleSelectionScreen();
    }

    // Rescuer flow → always ask for PIN
    if (_userRole == 'rescuer') {
      return const RescuerLoginScreen();
    }

    // Victim flow
    if (_userRole == 'victim') {
      return _isOnboarded
          ? const MainNavigationScreen()
          : const OnboardingScreen();
    }

    // Fallback
    return const RoleSelectionScreen();
  }
}
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _chooseVictim(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'victim');
    await prefs.setBool('onboarding_complete', false);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _chooseRescuer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'rescuer');

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RescuerLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpHop'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(               // 👈 FIXED
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.shield_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you a person needing help or a rescuer in the field?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Victim Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'I am a Victim / Normal User',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I want to send SOS, share my location, and message my contacts.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _chooseVictim(context),
                          child: const Text('Continue as Victim'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rescuer Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.volunteer_activism_outlined, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'I am a Rescuer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I want to see SOS requests and respond to them.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _chooseRescuer(context),
                          child: const Text('Continue as Rescuer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class RescuerLoginScreen extends StatefulWidget {
  const RescuerLoginScreen({super.key});

  @override
  State<RescuerLoginScreen> createState() => _RescuerLoginScreenState();
}

class _RescuerLoginScreenState extends State<RescuerLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '1234';
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500)); // small fake delay

    if (!mounted) return;

    if (pin == _correctPin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RescuerHomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
       resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        title: const Text('Rescuer Login'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_role');
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
     body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.badge_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter Rescuer PIN',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Only authorized responders can access SOS list.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login as Rescuer'),
             ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
class RescuerHomeScreen extends StatefulWidget {
  const RescuerHomeScreen({super.key});

  @override
  State<RescuerHomeScreen> createState() => _RescuerHomeScreenState();
}

class _RescuerHomeScreenState extends State<RescuerHomeScreen> {
  late final SosScanner _scanner;

  
  // Mutable list of SOS requests
final Map<String, SosRequest> _requests = {};
final Set<String> _resolved = {}; // accepted / rejected / rescued


  // Function to remove SOS after rescued
void removeRequest(String id) {
  _scanner.suppress(id); // 🔥 tell scanner
  setState(() {
    _resolved.add(id);
    _requests.remove(id);
  });
}



@override
void initState() {
  super.initState();
  print("🚨🚨 RESCUER initState CALLED 🚨🚨");
  _ensureBlePermissions().then((_) {
    _scanner = SosScanner();
    _scanner.start();

_scanner.stream.listen((map) {
  setState(() {
    for (final entry in map.entries) {
      final sosId = entry.key;
      final s = entry.value;
      final p = s.packet;

      if (_resolved.contains(sosId)) continue;

      _requests[sosId] = SosRequest(
  id: sosId,
  name: "Victim ${p.deviceId.substring(0, 4)}",
  emergencyType: p.emergency,
  latitude: p.lat,
  longitude: p.lon,
  signalText: _signalFromRssi(s.rssi),
  hopCount: p.hops,
  detectedAt: _requests[sosId]?.detectedAt ?? DateTime.now(),
);

    }
  });
});


  });
}
String _signalFromRssi(int rssi) {
  final abs = rssi.abs();

  if (abs < 50) return 'Very close';
  if (abs < 65) return 'Nearby';
  if (abs < 80) return 'Far';
  return 'Very far';
}

Future<void> _ensureBlePermissions() async {
  await FlutterBluePlus.turnOn();
}




   @override
void dispose() {
  _scanner.stop();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    print("🟦 RESCUER build()");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Dashboard'),
        centerTitle: true,
      ),

      body: _requests.isEmpty
          ? const Center(
              child: Text(
                'Scanning for SOS signals nearby…',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
            
         : ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _requests.length,
    itemBuilder: (context, index) {
      final sos = _requests.values.elementAt(index);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.report_problem, color: Colors.red),
                    title: Text('${sos.emergencyType} – ${sos.name}'),
                    subtitle: Text(
  'Detected: ${DateFormat('hh:mm a').format(sos.detectedAt)}\n'
  'Signal: ${sos.signalText}\n'
  'Hops: ${sos.hopCount}\n'
  'Tap to view & accept',
),


                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RescuerSosDetailScreen(
                            sosRequest: sos,
                            onRescued: () => removeRequest(sos.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class RescuerSosDetailScreen extends StatefulWidget {
  final SosRequest sosRequest;
  final VoidCallback onRescued;

  const RescuerSosDetailScreen({
    super.key,
    required this.sosRequest,
    required this.onRescued,
  });

  @override
  State<RescuerSosDetailScreen> createState() => _RescuerSosDetailScreenState();
}



class _RescuerSosDetailScreenState extends State<RescuerSosDetailScreen> {
  bool _accepted = false;
  bool _rescued = false;

  double? _rescuerLat;
double? _rescuerLon;
@override
void initState() {
  super.initState();
  _getRescuerLocation();
}

Future<void> _getRescuerLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _rescuerLat = position.latitude;
      _rescuerLon = position.longitude;
    });
  } catch (e) {
    print("GPS error: $e");
  }
}



 String _computeDirection() {
  if (_rescuerLat == null || _rescuerLon == null) {
    return "Getting rescuer location…";
  }

  final dLat = widget.sosRequest.latitude - _rescuerLat!;
  final dLon = widget.sosRequest.longitude - _rescuerLon!;

  String ns = '';
  String ew = '';

  if (dLat > 0.0005) ns = 'North';
  if (dLat < -0.0005) ns = 'South';
  if (dLon > 0.0005) ew = 'East';
  if (dLon < -0.0005) ew = 'West';

  if (ns.isEmpty && ew.isEmpty) return 'You are at the victim location';
  if (ns.isEmpty) return 'Move $ew';
  if (ew.isEmpty) return 'Move $ns';
  return 'Move $ns-$ew';
}

  void _accept() {
    setState(() {
      _accepted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS accepted. Use direction guidance to reach victim.'),
      ),
    );
  }

void _reject() {
  widget.onRescued();
  Navigator.pop(context);
}

  void _markRescued() {
  setState(() {
    _rescued = true;
  });

  widget.onRescued(); // 🔥 remove from list in previous screen

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Marked as rescued (demo).'),
    ),
  );

  Navigator.pop(context); // Go back to list
}


  @override
  Widget build(BuildContext context) {
    final sos = widget.sosRequest;
    final direction = _computeDirection();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
  24,
  24,
  24,
  24 + MediaQuery.of(context).viewInsets.bottom,
),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_pin_circle, size: 40, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sos.name.isEmpty ? 'Unknown victim' : sos.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Emergency: ${sos.emergencyType}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            const SizedBox(height: 8),
            Text('Signal strength: ${sos.signalText}'),

            const SizedBox(height: 16),
            Text('Hops: ${sos.hopCount}'),
const SizedBox(height: 8),

            Text(
              'Location (lat, lon): ${sos.latitude.toStringAsFixed(5)}, ${sos.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            if (!_accepted) ...[
              const Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _accept,
                      child: const Text('ACCEPT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      child: const Text('REJECT'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direction Guidance (Demo)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.explore, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              direction,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow this direction and watch distance indicators on ground.\n'
                        '(In a full version, this would be a live compass + map.)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _rescued ? null : _markRescued,
                  child: Text(_rescued ? 'RESCUED (Demo)' : 'MARK AS RESCUED'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==============================================
// ONBOARDING SCREENS
// ==============================================



// Main Onboarding Screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
    final Map<String, dynamic> _formData = {
    'name': '',
    'phone': '',
    'location': '',
    'bloodGroup': 'O+',
    'allergies': <String>[],
    'emergencyName': '',
    'emergencyPhone': '',
    'allowGPS': true,
  };


  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

   Future<void> _completeOnboarding() async {
    // Generate unique device ID
    final deviceId = _generateDeviceId();
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _formData['name']);
    await prefs.setString('user_phone', _formData['phone']);
    await prefs.setString('user_location', _formData['location']);
    await prefs.setString('user_blood_group', _formData['bloodGroup']);
    await prefs.setStringList('user_allergies', _formData['allergies']);
    await prefs.setString('emergency_name', _formData['emergencyName']);
    await prefs.setString('emergency_phone', _formData['emergencyPhone']);
    await prefs.setBool('allow_gps', _formData['allowGPS']);
    await prefs.setString('device_id', deviceId);
    await prefs.setBool('onboarding_complete', true);


    if (mounted) {
      // Show welcome message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${_formData['name']}! Your Device ID: $deviceId'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  String _generateDeviceId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final part1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup HelpHop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OnboardingStep1(
                  formData: _formData,
                  onNext: _nextPage,
                ),
                OnboardingStep2(
                  formData: _formData,
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                OnboardingStep3(
                  formData: _formData,
                  onComplete: _completeOnboarding,
                  onBack: _previousPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step 1: Basic Details
class OnboardingStep1 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onNext;

  const OnboardingStep1({
    super.key,
    required this.formData,
    required this.onNext,
  });

  @override
  State<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: Basic Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Help us personalize your experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Name Field
            TextFormField(
              initialValue: widget.formData['name'],
              decoration: const InputDecoration(
                labelText: 'Name / Nickname',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (value) => widget.formData['name'] = value,
            ),
            const SizedBox(height: 16),
            
            // Phone Field
            TextFormField(
              initialValue: widget.formData['phone'],
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => widget.formData['phone'] = value,
            ),
            const SizedBox(height: 16),
            
        
            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: Location & Health Info
class OnboardingStep2 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingStep2({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2> {
  final _formKey = GlobalKey<FormState>();
    final List<String> _availableAllergies = [
    'None',
    'Peanuts',
    'Shellfish',
    'Penicillin',
    'Insulin',
    'Aspirin',
    'Latex',
    'Dust',
  ];


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: Location & Health',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This info helps rescuers assist you better',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Location Field
            TextFormField(
              initialValue: widget.formData['location'],
              decoration: const InputDecoration(
                labelText: 'Home Location / Pin Code',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
              onChanged: (value) => widget.formData['location'] = value,
            ),
            const SizedBox(height: 16),
            
            // Blood Group Dropdown
            DropdownButtonFormField<String>(
              value: widget.formData['bloodGroup'],
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: Icon(Icons.bloodtype),
                border: OutlineInputBorder(),
              ),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((bg) => DropdownMenuItem(
                        value: bg,
                        child: Text(bg),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  widget.formData['bloodGroup'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Allergies Section
            Text(
              'Allergies / Medical Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
                        Wrap(
              spacing: 8,
              children: _availableAllergies.map((allergy) {
                final List<String> selectedAllergies =
                    (widget.formData['allergies'] as List<String>);
                final bool isSelected = selectedAllergies.contains(allergy);

                return FilterChip(
                  label: Text(allergy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (allergy == 'None') {
                        if (selected) {
                          // If "None" is selected → clear all others and keep only "None"
                          selectedAllergies
                            ..clear()
                            ..add('None');
                        } else {
                          // Unselect "None"
                          selectedAllergies.remove('None');
                        }
                      } else {
                        // If selecting any other allergy
                        if (selected) {
                          // Remove "None" if it was selected
                          selectedAllergies.remove('None');
                          selectedAllergies.add(allergy);
                        } else {
                          selectedAllergies.remove(allergy);
                        }
                      }
                      widget.formData['allergies'] = selectedAllergies;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Step 3: Emergency Contact & Permissions
class OnboardingStep3 extends StatefulWidget {
  final Map<String, dynamic> formData;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingStep3({
    super.key,
    required this.formData,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: Emergency Contact',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Who should we contact in an emergency?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Emergency Contact Name
            TextFormField(
              initialValue: widget.formData['emergencyName'],
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                prefixIcon: Icon(Icons.contacts),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact name';
                }
                return null;
              },
              onChanged: (value) => widget.formData['emergencyName'] = value,
            ),
            const SizedBox(height: 16),
            
            // Emergency Contact Phone
            TextFormField(
              initialValue: widget.formData['emergencyPhone'],
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Number',
                prefixIcon: Icon(Icons.phone_in_talk),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact number';
                }
                return null;
              },
              onChanged: (value) => widget.formData['emergencyPhone'] = value,
            ),
            const SizedBox(height: 24),
            
            // GPS Permission Checkbox
            Card(
              child: CheckboxListTile(
                title: const Text('Allow sharing my GPS location during SOS'),
                subtitle: const Text('Helps rescuers locate you quickly'),
                value: widget.formData['allowGPS'],
                onChanged: (value) {
                  setState(() {
                    widget.formData['allowGPS'] = value ?? true;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Setup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SosRequest {
  final String id;
  final String name;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final String signalText;
  final int hopCount;
  final DateTime detectedAt; // ✅ NEW

  const SosRequest({
    required this.id,
    required this.name,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.signalText,
    required this.hopCount,
    required this.detectedAt,
  });
}


// ==============================================
// MAIN NAVIGATION SCREEN
// ==============================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SOSScreen(),
    const ChatScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    const HelpScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Help',
          ),
        ],
      ),
    );
  }
}

// ==============================================
// SOS SCREEN
// ==============================================



class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  String _userName = '';
  String _lastSosTime = 'Never';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _lastSosTime = prefs.getString('last_sos_time') ?? 'Never';
    });
  }

  void _showEmergencyTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What type of emergency?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyOption('Flood', Icons.water),
            _buildEmergencyOption('Earthquake', Icons.vibration),
            _buildEmergencyOption('Fire', Icons.local_fire_department),
            _buildEmergencyOption('Landslide', Icons.landscape),
            _buildEmergencyOption('Other', Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(String type, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(type),
      onTap: () {
        Navigator.pop(context);
        _startCountdown(type);
      },
    );
  }

  void _startCountdown(String emergencyType) {
    int countdown = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (countdown > 0) {
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                setDialogState(() {
                  countdown--;
                });
              }
            });
          } else {
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                Navigator.pop(context);
                _sendSOS(emergencyType);
              }
            });
          }

          return AlertDialog(
            title: Text('Sending SOS: $emergencyType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$countdown',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendSOS(String emergencyType) async {
    print("🧪 SOS button pressed");
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('MMM dd, hh:mm a').format(DateTime.now());
    await prefs.setString('last_sos_time', now);

    setState(() {
      _lastSosTime = now;
    });

    // ⬇️ NEW CODE: start BLE broadcasting
   final deviceId = prefs.getString('device_id') ?? 'UNKNOWN';

// get GPS
double lat = 0.0;
double lon = 0.0;

try {
  final position = await LocationHelper.getLocation();
  lat = position?.latitude ?? 0.0;
  lon = position?.longitude ?? 0.0;
  print("🧪 Location fetched: $lat , $lon");
} catch (e) {
  print("🧪 Location error, continuing without GPS: $e");
}


final packet = SosPacket(
  sosId: SosPacket.generateSosId(), // ✅ REQUIRED
  deviceId: deviceId,
  lat: lat,
  lon: lon,
  emergency: emergencyType,
  hops: 0, // origin packet
);

print("🧪 About to start BLE advertising");

await advertiser.start(packet);



    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS broadcast started via Bluetooth\nType: $emergencyType',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ⬇️ STOP BLE BROADCAST WHEN LEAVING THE SCREEN
  @override
  void dispose() {
    //advertiser.stop();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpHop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AlertScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Welcome Message
            Text(
              'Welcome, $_userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),

            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'GPS',
                    '12.9716° N, 77.5946° E',
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Battery',
                    '85%',
                    Icons.battery_full,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Wi-Fi',
                    'Offline',
                    Icons.wifi_off,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Bluetooth',
                    'Active',
                    Icons.bluetooth,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // SOS Button
            GestureDetector(
              onTap: _showEmergencyTypeDialog,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SEND SOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Last SOS Time
            Text(
              'Last SOS: $_lastSosTime',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Note Field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add note (e.g., trapped under stairs)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}


// ==============================================
// CHAT SCREEN
// ==============================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _userName = '';
  final List<Map<String, String>> _messages = [
    {
      'sender': 'You',
      'text': 'I am safe for now, but the area is flooded.',
      'time': '10:23 AM',
      'isMe': 'true',
    },
    {
      'sender': 'Emergency Contact',
      'text': 'Stay where you are, I’m informing rescue team.',
      'time': '10:25 AM',
      'isMe': 'false',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Me';
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      _messages.add({
        'sender': _userName,
        'text': text,
        'time': now,
        'isMe': 'true',
      });
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Optional info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth, size: 16, color: Colors.blue[900]),
                const SizedBox(width: 8),
                Text(
                  'Messages sent via local mesh (offline)',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final bool isMe = msg['isMe'] == 'true';
                return _buildMessageBubble(
                  msg['sender'] ?? '',
                  msg['text'] ?? '',
                  msg['time'] ?? '',
                  isMe,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      String sender, String message, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                sender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// PROFILE SCREEN
// ==============================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userData = {
        'name': prefs.getString('user_name') ?? '',
        'phone': prefs.getString('user_phone') ?? '',
        
        'location': prefs.getString('user_location') ?? '',
        'bloodGroup': prefs.getString('user_blood_group') ?? '',
        'allergies': prefs.getStringList('user_allergies') ?? [],
        'emergencyName': prefs.getString('emergency_name') ?? '',
        'emergencyPhone': prefs.getString('emergency_phone') ?? '',
        'deviceId': prefs.getString('device_id') ?? '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile in Settings')),
              );
            },
          ),
        ],
      ),
      body: _userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      _userData['name']?.isNotEmpty == true
                          ? _userData['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Device ID: ${_userData['deviceId']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Personal Information
                  _buildSectionCard(
                    'Personal Information',
                    [
                      _buildInfoRow(Icons.phone, 'Phone', _userData['phone'] ?? 'Not provided'),
                     
                      _buildInfoRow(Icons.location_on, 'Location', _userData['location'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Medical Information
                  _buildSectionCard(
                    'Medical Information',
                    [
                      _buildInfoRow(Icons.bloodtype, 'Blood Group', _userData['bloodGroup'] ?? ''),
                      _buildInfoRow(
                        Icons.medical_information,
                        'Allergies',
                        (_userData['allergies'] as List).isEmpty
                            ? 'None'
                            : (_userData['allergies'] as List).join(', '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Emergency Contact
                  _buildSectionCard(
                    'Emergency Contact',
                    [
                      _buildInfoRow(Icons.contacts, 'Name', _userData['emergencyName'] ?? ''),
                      _buildInfoRow(Icons.phone_in_talk, 'Phone', _userData['emergencyPhone'] ?? ''),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// SETTINGS SCREEN
// ==============================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _anonymousMode = false;
  bool _lowPowerMode = false;
  bool _allowGPS = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _anonymousMode = prefs.getBool('anonymous_mode') ?? false;
      _lowPowerMode = prefs.getBool('low_power_mode') ?? false;
      _allowGPS = prefs.getBool('allow_gps') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will clear all your information and restart the onboarding process. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Privacy Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Privacy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Anonymous Mode'),
            subtitle: const Text('Hide your name in local chat'),
            value: _anonymousMode,
            onChanged: (value) {
              setState(() {
                _anonymousMode = value;
              });
              _saveSetting('anonymous_mode', value);
            },
          ),
          SwitchListTile(
            title: const Text('Share GPS Location'),
            subtitle: const Text('Allow location sharing during SOS'),
            value: _allowGPS,
            onChanged: (value) {
              setState(() {
                _allowGPS = value;
              });
              _saveSetting('allow_gps', value);
            },
          ),
          const Divider(),
          
          // Connectivity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Connectivity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Low-Power Scan Mode'),
            subtitle: const Text('Conserve battery for Bluetooth scanning'),
            value: _lowPowerMode,
            onChanged: (value) {
              setState(() {
                _lowPowerMode = value;
              });
              _saveSetting('low_power_mode', value);
            },
          ),
          const Divider(),
          
          // Data Management
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Profile Data'),
            subtitle: const Text('Save your profile as a file'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Data'),
            subtitle: const Text('Clear profile and restart setup'),
            onTap: _resetData,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Disaster Alert'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.orange[800],
            ),
            const SizedBox(height: 16),
            const Text(
              'Official Disaster Alert',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Severe weather conditions predicted in your area.\n\n'
              'Please take the following precautions immediately:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildInstruction('Move to higher ground or a safe shelter.'),
            _buildInstruction('Charge your phone and power banks.'),
            _buildInstruction('Keep Wi-Fi and Bluetooth turned ON.'),
            _buildInstruction('Keep essential medicines and documents ready.'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ACKNOWLEDGE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 24),
          const SizedBox(width: 4),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}



// ==============================================
// HELP SCREEN
// ==============================================

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Info'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'HelpHop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure, Offline-First Disaster Response',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // How to Use SOS
            Text(
              'How to Use SOS Feature',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '1',
              'Press the red SOS button on the home screen',
            ),
            _buildHelpItem(
              '2',
              'Select your emergency type (Flood, Fire, etc.)',
            ),
            _buildHelpItem(
              '3',
              'Wait for 5-second countdown or cancel if needed',
            ),
            _buildHelpItem(
              '4',
              'Your SOS will be broadcast to nearby devices via mesh network',
            ),
            const SizedBox(height: 24),
            
            // How Local Chat Works
            Text(
              'How Local Chat Works Offline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '📱',
              'Uses Bluetooth and Wi-Fi Direct for device-to-device messaging',
            ),
            _buildHelpItem(
              '🌐',
              'Forms a mesh network with nearby phones (no internet needed)',
            ),
            _buildHelpItem(
              '💬',
              'Messages relay through multiple devices to reach farther',
            ),
            _buildHelpItem(
              '🔒',
              'All communications are encrypted end-to-end',
            ),
            const SizedBox(height: 24),
            
            // Safety Tips
            Text(
              'Safety Tips for Disasters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildSafetyTip('Stay calm and assess your situation'),
            _buildSafetyTip('Send SOS immediately if trapped or injured'),
            _buildSafetyTip('Conserve phone battery - enable low-power mode'),
            _buildSafetyTip('Share your location with local chat'),
            _buildSafetyTip('Follow instructions from rescue teams'),
            _buildSafetyTip('Keep your emergency contact informed'),
            const SizedBox(height: 32),
            
            // Team Info
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Our Team',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Built with ❤️ by',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Huda Fatimah\nManyashree S\nDevisri Harshini Baramal\nG. Roweena Siphora',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DTL Project:\nSecure Mesh-based Disaster Response App',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }
}