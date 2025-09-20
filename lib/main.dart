import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

// IMPORTANT: This file must be generated using the FlutterFire CLI.
// Run 'flutterfire configure' in your project terminal to create it.
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(ErrorApp(errorMessage: 'Firebase Initialization Failed. Please run `flutterfire configure` and try again.'));
    return;
  }
  runApp(SmartTrafficApp());
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({Key? key, required this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text(
                  'Application Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Global state for simulating real-time data
class AppData extends ChangeNotifier {
  final Map<String, dynamic> _trafficData = {
    'trafficFlow': 0.75,
    'incidentCount': 5,
    'vehicleSpeed': 45.0,
  };
  final List<Map<String, dynamic>> _incidents = [
    {'id': '1', 'type': 'Accident', 'location': 'Main & Oak', 'resolved': false},
    {'id': '2', 'type': 'Road Work', 'location': 'Highway 101', 'resolved': false},
    {'id': '3', 'type': 'Flood', 'location': 'Riverfront Blvd', 'resolved': false},
  ];

  Map<String, dynamic> get trafficData => _trafficData;
  List<Map<String, dynamic>> get incidents => _incidents;

  void updateTrafficData() {
    _trafficData['trafficFlow'] = Random().nextDouble();
    _trafficData['incidentCount'] = Random().nextInt(10);
    _trafficData['vehicleSpeed'] = 20 + Random().nextInt(40).toDouble();
    notifyListeners();
  }

  void resolveIncident(String id) {
    final index = _incidents.indexWhere((inc) => inc['id'] == id);
    if (index != -1) {
      _incidents[index]['resolved'] = true;
      notifyListeners();
    }
  }

  void addIncident(Map<String, dynamic> newIncident) {
    _incidents.add(newIncident);
    notifyListeners();
  }
}

class SmartTrafficApp extends StatelessWidget {
  final AppData _appData = AppData();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _appData,
      child: MaterialApp(
        title: 'Smart Traffic App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Montserrat',
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.indigo,
            accentColor: Color(0xFFF7F2E2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF2E3B5C),
            foregroundColor: Colors.white,
          ),
          scaffoldBackgroundColor: Color(0xFFF7F2E2),
        ),
        home: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E3B5C)),
            ),
          );
        }
        if (snapshot.hasData) {
          return HomeScreen(); // This will now be the new dashboard-like screen
        } else {
          return LandingScreen();
        }
      },
    );
  }
}

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3B5C), Color(0xFF1E283A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.traffic,
                size: 120,
                color: Color(0xFFF26B5E),
              ),
              SizedBox(height: 20),
              Text(
                'Smart Traffic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Intelligent City Management',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 60),
              _buildAuthButton(
                context,
                'Login',
                Icons.login,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
              ),
              SizedBox(height: 24),
              _buildAuthButton(
                context,
                'Emergency Services',
                Icons.local_hospital,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyServicesHome())),
                isEmergency: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, String text, IconData icon, VoidCallback onPressed, {bool isEmergency = false}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 280,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: isEmergency ? [Color(0xFFF26B5E), Color(0xFFC7433A)] : [Color(0xFFF7F2E2), Color(0xFFE2D6C6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isEmergency ? Colors.white : Color(0xFF2E3B5C)),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEmergency ? Colors.white : Color(0xFF2E3B5C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Navigate to the previous screen, which is AuthGate, which will then redirect
      // to the correct home screen.
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.code == 'user-not-found' || e.code == 'wrong-password'
            ? 'Invalid email or password.'
            : 'An authentication error occurred: ${e.message}';
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'An unknown error occurred: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3B5C), Color(0xFF1E283A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                SizedBox(height: 40),
                _buildTextField(_emailController, 'Email', Icons.email),
                SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorText!,
                      style: TextStyle(color: Color(0xFFF26B5E), fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFF7F2E2)))
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF2E3B5C),
                          backgroundColor: Color(0xFFF7F2E2),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                        ),
                        child: Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                  },
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF7F2E2), width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;
  String? _errorText;
  bool _isLoading = false;

  final List<String> _roles = [
    'City Traffic Admin',
    'Traffic Control Operator',
    'Public User',
  ];

  Future<void> _register() async {
    if (_selectedRole == null) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Please select a role.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'role': _selectedRole,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.code == 'weak-password'
            ? 'The password provided is too weak.'
            : e.code == 'email-already-in-use'
                ? 'An account already exists for that email.'
                : 'An authentication error occurred: ${e.message}';
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'An unknown error occurred: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3B5C), Color(0xFF1E283A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Create an Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Please fill in your details',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 40),
                _buildTextField(_firstNameController, 'First Name', Icons.person),
                SizedBox(height: 16),
                _buildTextField(_lastNameController, 'Last Name', Icons.person_outline),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedRole = newValue);
                  },
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.account_circle, color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF7F2E2), width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  dropdownColor: Color(0xFF2E3B5C),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 16),
                _buildTextField(_emailController, 'Email', Icons.email),
                SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorText!,
                      style: TextStyle(color: Color(0xFFF26B5E), fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFF7F2E2)))
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF2E3B5C),
                          backgroundColor: Color(0xFFF7F2E2),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                        ),
                        child: Text('Register', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF7F2E2), width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

// --- NEW HOMESCREEN IMPLEMENTATION ---
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'Public User';
  bool _isLoadingRole = true;
  int _selectedIndex = 0; // For bottom navigation if we reintroduce it

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['role'] as String? ?? 'Public User';
          _isLoadingRole = false;
        });
      } else {
        setState(() {
          _isLoadingRole = false;
        });
      }
    } else {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  // Function to navigate to specific pages based on role and card tap
  void _navigateToPage(String pageName) {
    Widget targetPage;
    switch (pageName) {
      case 'Live Traffic':
        targetPage = InteractiveMapPage();
        break;
      case 'Incidents':
        targetPage = IncidentManagementPage(); // Or a detailed incident list
        break;
      case '3D City Visualization':
        targetPage = ThreeDVisualizationPage();
        break;
      case 'Weather Integration':
        targetPage = WeatherIntegrationPage();
        break;
      case 'Public Transport':
        targetPage = PublicTransportationPage();
        break;
      case 'Emergency Route Planning':
        targetPage = EmergencyRoutePlanningPage();
        break;
      case 'Report Incident': // For public users
        targetPage = IncidentReportingPage();
        break;
      case 'Profile':
        targetPage = ProfileScreen();
        break;
      case 'Dashboard':
        targetPage = DashboardPage(); // The original dashboard page
        break;
      case 'Signal Control':
        targetPage = SignalControlPage();
        break;
      default:
        targetPage = Text('Page Not Found'); // Fallback
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF26B5E)),
        ),
      );
    }

    // Determine which cards to show based on user role
    List<Map<String, dynamic>> dashboardCards = [];
    if (_userRole == 'City Traffic Admin') {
      dashboardCards = [
        {'title': 'Dashboard', 'icon': Icons.dashboard, 'page': 'Dashboard'},
        {'title': 'Live Traffic', 'icon': Icons.car_crash, 'page': 'Live Traffic'},
        {'title': 'Incidents', 'icon': Icons.warning, 'page': 'Incidents'},
        {'title': 'Signal Control', 'icon': Icons.lightbulb, 'page': 'Signal Control'},
        {'title': '3D City Visualization', 'icon': Icons.threed_rotation, 'page': '3D City Visualization'},
        {'title': 'Weather Integration', 'icon': Icons.cloud_queue, 'page': 'Weather Integration'},
        {'title': 'Public Transport', 'icon': Icons.directions_bus, 'page': 'Public Transport'},
        {'title': 'Emergency Route Planning', 'icon': Icons.alt_route, 'page': 'Emergency Route Planning'},
      ];
    } else if (_userRole == 'Traffic Control Operator') {
      dashboardCards = [
        {'title': 'Dashboard', 'icon': Icons.dashboard, 'page': 'Dashboard'},
        {'title': 'Live Traffic', 'icon': Icons.car_crash, 'page': 'Live Traffic'},
        {'title': 'Incidents', 'icon': Icons.warning, 'page': 'Incidents'},
        {'title': 'Signal Control', 'icon': Icons.lightbulb, 'page': 'Signal Control'},
      ];
    } else { // Public User
      dashboardCards = [
        {'title': 'Live Traffic', 'icon': Icons.car_crash, 'page': 'Live Traffic'},
        {'title': 'Report Incident', 'icon': Icons.report, 'page': 'Report Incident'},
      ];
    }

    return Scaffold(
      backgroundColor: Color(0xFF16223a), // Background color from HTML
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Container(
                margin: EdgeInsets.all(12.0),
                padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                decoration: BoxDecoration(
                  color: Color(0xFF222e46),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.traffic, color: Color(0xFFf76a6a), size: 30),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Traffic',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Metropolis City Management',
                                style: TextStyle(
                                  color: Color(0xFFbfbfbf),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF1e2944),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                                  ),
                                ),
                              ),
                              Icon(Icons.search, color: Color(0xFFfd6868), size: 20),
                            ],
                          ),
                        ),
                        SizedBox(width: 11),
                        Icon(Icons.question_mark_rounded, color: Color(0xFFfd6868), size: 20),
                        SizedBox(width: 9),
                        Icon(Icons.notifications, color: Color(0xFFfd6868), size: 20),
                        SizedBox(width: 9),
                        IconButton(
                          icon: Icon(Icons.logout, color: Color(0xFFfd6868)),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu Bar (simplified for Flutter, can be expanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMenuBarButton(context, 'Dashboard', Icons.dashboard, () => _navigateToPage('Dashboard')),
                    _buildMenuBarButton(context, 'Reports', Icons.file_copy, () => _navigateToPage('Incident Management')), // Example
                    _buildMenuBarButton(context, 'Profile', Icons.person, () => _navigateToPage('Profile')),
                    _buildMenuBarButton(context, 'Settings', Icons.settings, () => print('Settings tapped')),
                  ],
                ),
              ),

              // Main Content Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  children: [
                    // Grid Cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2, // Adjust as needed
                      ),
                      itemCount: dashboardCards.length,
                      itemBuilder: (context, index) {
                        final card = dashboardCards[index];
                        return _buildDashboardCard(
                          context,
                          card['title'],
                          card['icon'],
                          () => _navigateToPage(card['page']),
                        );
                      },
                    ),
                    SizedBox(height: 20),

                    // Real-time Traffic Conditions
                    _buildTrafficDashboardSection(),
                    SizedBox(height: 20),

                    // City Map Section
                    _buildCityMapSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBarButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Color(0xFFcfcfff), size: 18),
      label: Text(
        text,
        style: TextStyle(color: Color(0xFFcfcfff), fontSize: 15),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF232d49),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.19),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFFfd6868), size: 32),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficDashboardSection() {
    return Consumer<AppData>(
      builder: (context, appData, child) {
        final data = appData.trafficData;
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF232d49),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Real-time Traffic Conditions',
                style: TextStyle(
                  color: Color(0xFFff7676),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  _buildTrafficStatCard(
                    'Congestion Level',
                    '${(data['trafficFlow'] * 100).toStringAsFixed(0)}%',
                  ),
                  SizedBox(height: 12),
                  _buildTrafficStatCard(
                    'Incidents Reported',
                    '${data['incidentCount']}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrafficStatCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF1e2944),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Color(0xFFbfbfbf), fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCityMapSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF232d49),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City Map',
            style: TextStyle(
              color: Color(0xFFff7676),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          // Reusing the InteractiveMapPage for the map display
          SizedBox(
            height: 200,
            child: InteractiveMapPage(),
          ),
        ],
      ),
    );
  }
}

// Custom Card Widget for a uniform look (kept for other pages)
class CustomCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;

  CustomCard({required this.child, this.color = Colors.white, this.elevation = 4});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }
}

// ---
// ## Real-time Traffic Monitoring Dashboard (Original, now accessible via card)
// This page uses a ChangeNotifier to simulate real-time data updates.
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      Provider.of<AppData>(context, listen: false).updateTrafficData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Consumer<AppData>(
        builder: (context, appData, child) {
          final data = appData.trafficData;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDashboardMetric(
                  context,
                  'Average Speed',
                  '${data['vehicleSpeed'].toStringAsFixed(1)} mph',
                  Icons.speed,
                  Colors.green,
                ),
                _buildDashboardMetric(
                  context,
                  'Incident Count',
                  '${data['incidentCount']}',
                  Icons.report_problem,
                  Colors.red,
                ),
                _buildDashboardMetric(
                  context,
                  'Traffic Flow',
                  '${(data['trafficFlow'] * 100).toStringAsFixed(0)}%',
                  Icons.waves,
                  Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardMetric(BuildContext context, String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 40, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---
// ## Interactive City Map (Original, now integrated into HomeScreen and accessible via card)
// The map displays live traffic and simulated incident markers.
class InteractiveMapPage extends StatefulWidget {
  @override
  _InteractiveMapPageState createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  GoogleMapController? _mapController;
  final LatLng _initialCameraPosition = LatLng(37.7749, -122.4194);
  Set<Marker> _markers = {};
  StreamSubscription<QuerySnapshot>? _incidentSubscription;

  @override
  void initState() {
    super.initState();
    _listenForIncidents();
  }

  @override
  void dispose() {
    _incidentSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncidents() {
    _incidentSubscription = FirebaseFirestore.instance.collection('incidents').snapshots().listen((snapshot) {
      final newMarkers = <Marker>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            infoWindow: InfoWindow(title: data['type'] as String),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
      setState(() {
        _markers = newMarkers;
      });
    }, onError: (error) {
      print("Error listening for incidents: $error");
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // You can now programmatically control the map
  }

  void _onMapTap(LatLng position) {
    // This is a good place to add a new marker, for example, for reporting an incident
    print('Tapped on map at: $position');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 12),
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          trafficEnabled: true,
          markers: _markers,
          onTap: _onMapTap,
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: CustomCard(
            color: Color(0xFF2E3B5C),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Live traffic data powered by Google Maps.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---
// ## Traffic Signal Control (Original, now accessible via card)
// An interactive UI for controlling traffic signals.
class SignalControlPage extends StatefulWidget {
  @override
  _SignalControlPageState createState() => _SignalControlPageState();
}

class _SignalControlPageState extends State<SignalControlPage> {
  double _greenLightDuration = 30;
  double _yellowLightDuration = 3;
  bool _isManualOverride = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signal Control'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                children: [
                  _buildControlSlider(
                    'Green Light Duration',
                    Icons.lightbulb,
                    Colors.green,
                    _greenLightDuration,
                    (value) => setState(() => _greenLightDuration = value),
                    10,
                    60,
                  ),
                  _buildControlSlider(
                    'Yellow Light Duration',
                    Icons.lightbulb,
                    Colors.amber,
                    _yellowLightDuration,
                    (value) => setState(() => _yellowLightDuration = value),
                    2,
                    10,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manual Override', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isManualOverride,
                        onChanged: (value) => setState(() => _isManualOverride = value),
                        activeColor: Color(0xFF2E3B5C),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.send),
                    label: Text('Apply Settings'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFFF7F2E2),
                      backgroundColor: Color(0xFF2E3B5C),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSlider(String title, IconData icon, Color color, double value, Function(double) onChanged, double min, double max) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title: ${value.toStringAsFixed(0)}s',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }
}

// ---
// ## Incident Reporting & Management Tools (Original, now accessible via card)
// A management console for incidents.
class IncidentManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Management'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Consumer<AppData>(
        builder: (context, appData, child) {
          final incidents = appData.incidents;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final isResolved = incident['resolved'];
                return CustomCard(
                  color: isResolved ? Colors.green[100]! : Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle : Icons.warning,
                        color: isResolved ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incident: ${incident['type']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: isResolved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              'Location: ${incident['location']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                decoration: isResolved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isResolved)
                        ElevatedButton(
                          onPressed: () {
                            appData.resolveIncident(incident['id']);
                          },
                          child: Text('Resolve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E3B5C),
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
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

// ---
// ## Incident Reporting (for Public Users) (Original, now accessible via card)
// A simple page for public users to report incidents.
class IncidentReportingPage extends StatefulWidget {
  @override
  _IncidentReportingPageState createState() => _IncidentReportingPageState();
}

class _IncidentReportingPageState extends State<IncidentReportingPage> {
  final _incidentDescriptionController = TextEditingController();
  String? _selectedIncidentType;
  final List<String> _incidentTypes = [
    'Traffic Accident',
    'Road Work',
    'Road Obstruction',
    'Flood',
    'Other',
  ];
  String? _message;
  bool _isLoading = false;

  Future<void> _submitIncidentReport() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await FirebaseFirestore.instance.collection('incidents').add({
        'type': _selectedIncidentType ?? 'Other',
        'description': _incidentDescriptionController.text.isEmpty ? 'No description' : _incidentDescriptionController.text,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'reporterId': FirebaseAuth.instance.currentUser?.uid,
      });

      setState(() {
        _message = 'Incident reported successfully!';
        _incidentDescriptionController.clear();
        _selectedIncidentType = null;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to report incident. Please try again.';
      });
      print('Error submitting incident: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Incident'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: CustomCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.report, size: 80, color: Color(0xFFF26B5E)),
                SizedBox(height: 16),
                Text(
                  'Report an Incident',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Help us by reporting traffic issues in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedIncidentType,
                  items: _incidentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedIncidentType = newValue);
                  },
                  decoration: InputDecoration(
                    labelText: 'Incident Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _incidentDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _submitIncidentReport,
                    icon: Icon(Icons.add_circle),
                    label: Text('Submit Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E3B5C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.contains('successfully') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---
// ## Emergency Route Planning Tools (Original, now accessible via card)
// A page dedicated to emergency route planning.
class EmergencyRoutePlanningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Route Planning'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Center(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route, size: 80, color: Color(0xFFF26B5E)),
              SizedBox(height: 16),
              Text(
                'Emergency Route Planning',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Generate optimal routes for emergency vehicles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// ## 3D City Visualization (Original, now accessible via card)
// A page to display a 3D city model.
class ThreeDVisualizationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D City Visualization'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.threed_rotation, size: 150, color: Colors.grey[300]),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Text(
                '3D City Visualization',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Text(
                'An interactive 3D model of the city for advanced monitoring.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---
// ## Weather Integration (Original, now accessible via card)
// A page to display weather data.
class WeatherIntegrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Integration'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Center(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud, size: 80, color: Colors.blue[300]),
              SizedBox(height: 16),
              Text(
                'Weather Integration',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Use real-time weather data to predict and manage traffic.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// ## Public Transportation Integration (Original, now accessible via card)
// A page to display public transportation data.
class PublicTransportationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Transportation'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Center(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bus, size: 80, color: Colors.teal[300]),
              SizedBox(height: 16),
              Text(
                'Public Transportation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'View live bus, train, and public transit schedules.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// ## Unique User Profile Page with Editing (Original, now accessible via card)
// This profile page is designed to be visually appealing and functional.
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = 'Loading...';
  String _lastName = '';
  String _email = 'Loading...';
  String _role = 'Loading...';
  bool _isEditing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _firstName = data?['firstName'] ?? 'No Name';
          _lastName = data?['lastName'] ?? '';
          _email = data?['email'] ?? 'No Email';
          _role = data?['role'] ?? 'Public User';
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
        });
      }
    }
  }

  void _toggleEditing() {
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      });
      _fetchUserData();
      _toggleEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF2E3B5C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFF2E3B5C), Color(0xFF4A6572)],
                          center: Alignment.topRight,
                          radius: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 15,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Color(0xFFF7F2E2),
                      // In a real app, you would load the image here
                      // backgroundImage: NetworkImage('your_profile_image_url'),
                      child: Icon(Icons.person, size: 80, color: Color(0xFF2E3B5C)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // This section would be used to handle image picking and uploading.
                          // You need to add the 'image_picker' package to your pubspec.yaml.
                          // For example:
                          // import 'package:image_picker/image_picker.dart';
                          //
                          // final ImagePicker picker = ImagePicker();
                          // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          //
                          // You would then upload the image to Firebase Storage and update the user's
                          // profile picture URL in Firestore.
                          //
                          // NOTE: For this code to be fully functional, you would need to add
                          // the required packages and implement the file upload logic.
                          //
                          // We will simulate the action below:
                          print('Simulating profile picture upload...');
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF26B5E),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                CustomCard(
                  child: Column(
                    children: [
                      if (_isEditing)
                        Column(
                          children: [
                            TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF2E3B5C),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Save'),
                                ),
                                ElevatedButton(
                                  onPressed: _toggleEditing,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildProfileInfoRow('Name', '$_firstName $_lastName'),
                            _buildProfileInfoRow('Email', _email),
                            _buildProfileInfoRow('Role', _role),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _toggleEditing,
                              icon: Icon(Icons.edit),
                              label: Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF26B5E),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ---
// ## Emergency Services Landing Page
// This page provides a landing for emergency-specific features.
class EmergencyServicesHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Services'),
        backgroundColor: Color(0xFFF26B5E),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF26B5E), Color(0xFFC7433A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.alt_route,
                title: 'Priority Routing',
                description: 'Quickly find the fastest route to an emergency scene.',
                color: Color(0xFFF7F2E2),
                onTap: () {},
              ),
              SizedBox(height: 24),
              _buildFeatureCard(
                context,
                icon: Icons.add_alert,
                title: 'Instant Report',
                description: 'Report accidents and roadblocks instantly with live location.',
                color: Color(0xFFF7F2E2),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyInstantReportPage()));
                },
              ),
              SizedBox(height: 24),
              _buildFeatureCard(
                context,
                icon: Icons.local_hospital,
                title: 'Emergency Helplines',
                description: 'Find nearby emergency contact numbers.',
                color: Color(0xFFF7F2E2),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyHelplinesPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required String description, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 50, color: Color(0xFFF26B5E)),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3B5C),
                ),
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A6572),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// ## Emergency Instant Report Page
// Allows users to instantly report an incident with their live location.
class EmergencyInstantReportPage extends StatefulWidget {
  @override
  _EmergencyInstantReportPageState createState() => _EmergencyInstantReportPageState();
}

class _EmergencyInstantReportPageState extends State<EmergencyInstantReportPage> {
  String? _message;
  bool _isLoading = false;

  Future<void> _submitInstantReport() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await FirebaseFirestore.instance.collection('incidents').add({
        'type': 'Emergency Report',
        'description': 'Instant emergency report from public user.',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'reporterId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user',
      });

      setState(() {
        _message = 'Emergency reported successfully! Help is on the way.';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to submit report. Please check your location services.';
      });
      print('Error submitting instant report: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instant Report'),
        backgroundColor: Color(0xFFF26B5E),
      ),
      body: Center(
        child: CustomCard(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_alert, size: 80, color: Color(0xFFF26B5E)),
              SizedBox(height: 16),
              Text(
                'Instant Emergency Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'This will send an emergency alert with your current location.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _submitInstantReport,
                  icon: Icon(Icons.send_rounded),
                  label: Text('Send Emergency Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E3B5C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('successfully') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// ## Emergency Helplines Page
// Displays nearby emergency helpline numbers based on location.
class EmergencyHelplinesPage extends StatefulWidget {
  @override
  _EmergencyHelplinesPageState createState() => _EmergencyHelplinesPageState();
}

class _EmergencyHelplinesPageState extends State<EmergencyHelplinesPage> {
  final List<Map<String, String>> emergencyNumbers = [
    {'name': 'Police', 'number': '100'},
    {'name': 'Fire Service', 'number': '101'},
    {'name': 'Ambulance', 'number': '102'},
    {'name': 'National Emergency', 'number': '112'},
    {'name': 'Women Helpline', 'number': '1091'},
    {'name': 'Traffic Police', 'number': '103'},
  ];

  String _currentLocation = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      if(mounted) {
        setState(() {
          _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _currentLocation = 'Could not get location.';
        });
      }
    }
  }

  void _callNumber(String number) async {
    final uri = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(uri))) {
      await launchUrl(Uri.parse(uri));
    } else {
      print('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Helplines'),
        backgroundColor: Color(0xFFF26B5E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF2E3B5C), size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Your Current Location:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _currentLocation,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'National Emergency Numbers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E3B5C)),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: emergencyNumbers.length,
              itemBuilder: (context, index) {
                final helpline = emergencyNumbers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CustomCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              helpline['name']!,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              helpline['number']!,
                              style: TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _callNumber(helpline['number']!),
                          icon: Icon(Icons.phone),
                          label: Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
