import 'dart:math' as math;

import 'package:labin/backend/labin_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LabinBackend.initialize();
  runApp(const LabinApp());
}

class LabinApp extends StatefulWidget {
  const LabinApp({super.key});

  @override
  State<LabinApp> createState() => _LabinAppState();
}

class _LabinAppState extends State<LabinApp> {
  bool darkMode = false;
  int startStage = 0;

  void toggleTheme(bool value) {
    setState(() => darkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Labin',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: LabinTheme.light,
      darkTheme: LabinTheme.dark,
      home: switch (startStage) {
        0 => SplashScreen(onDone: () => setState(() => startStage = 1)),
        1 => OnboardingScreen(onFinished: () => setState(() => startStage = 2)),
        _ => const AuthScreen(),
      },
      routes: {
        '/tracking': (_) => const TrackingScreen(),
        '/loan': (_) => const LoanFormScreen(),
        '/reservation': (_) => const ReservationScreen(),
        '/report': (_) => const DamageReportScreen(),
        '/announcements': (_) => const AnnouncementScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/staff': (_) => const StaffPortalScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          return MaterialPageRoute(
            builder: (_) =>
                MainShell(darkMode: darkMode, onThemeChanged: toggleTheme),
          );
        }
        return null;
      },
    );
  }
}

class LabinTheme {
  static const primary = Color(0xFF1E1B4B);
  static const primaryLight = Color(0xFF4F46E5);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const bg = Color(0xFFF8FAFC);
  static const darkBg = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryLight,
      primary: primary,
      secondary: accent,
      surface: Colors.white,
      error: danger,
    ),
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: false,
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: accent,
      primary: primaryLight,
      secondary: accent,
      surface: darkSurface,
      error: danger,
    ),
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: false,
    ),
  );
}

class SupabaseConfig {
  static const url = String.fromEnvironment('LABIN_SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'LABIN_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('LABIN_SUPABASE_ANON_KEY'),
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

class LabinBackend {
  static bool initialized = false;

  static SupabaseClient? get client {
    if (!initialized) return null;
    return Supabase.instance.client;
  }

  static LabinRepository get repository => LabinRepository(client: client);

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    initialized = true;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    Future.delayed(const Duration(milliseconds: 2300), widget.onDone);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBox(
        child: Center(
          child: FadeTransition(
            opacity: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: .76, end: 1).animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: const LabinLogo(size: 94),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Labin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lab Smarter, Not Harder',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 72),
                SizedBox(
                  width: 160,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (_, _) => LinearProgressIndicator(
                      value: math.min(controller.value, 1),
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final slides = const [
    OnboardData(
      title: 'Satu App, Semua Kebutuhan Lab',
      body:
          'Dari peminjaman alat sampai reservasi ruangan, semua bisa dari genggaman.',
      icon: Icons.science_rounded,
      colors: [LabinTheme.primary, Color(0xFF312E81)],
    ),
    OnboardData(
      title: 'Jadwal Lab Tanpa Drama',
      body:
          'Cek slot kosong, booking ruangan, dan dapat reminder otomatis sebelum sesi mulai.',
      icon: Icons.event_available_rounded,
      colors: [Color(0xFF0891B2), LabinTheme.accent],
    ),
    OnboardData(
      title: 'Real-Time, Always On-Time',
      body:
          'Notifikasi status peminjaman, jadwal piket, dan pengumuman langsung masuk ke HP kamu.',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFF7C3AED), LabinTheme.primaryLight],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: controller,
        onPageChanged: (value) => setState(() => page = value),
        itemCount: slides.length,
        itemBuilder: (_, index) {
          final slide = slides[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: slide.colors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 620;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LabinWordmark(color: Colors.white),
                          SizedBox(height: compact ? 28 : 58),
                          Center(
                            child: Transform.scale(
                              scale: compact ? .72 : 1,
                              child: LabIllustration(
                                icon: slide.icon,
                                page: index,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 44),
                          Text(
                            slide.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 26 : 31,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                          SizedBox(height: compact ? 24 : 46),
                          Row(
                            children: List.generate(
                              slides.length,
                              (dot) => AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                margin: const EdgeInsets.only(right: 8),
                                height: 9,
                                width: dot == page ? 30 : 9,
                                decoration: BoxDecoration(
                                  color: dot == page
                                      ? Colors.white
                                      : Colors.white30,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (page == slides.length - 1) ...[
                            GradientButton(
                              label: 'Mulai Sekarang',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: widget.onFinished,
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: widget.onFinished,
                              child: const Center(
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ] else
                            GradientButton(
                              label: 'Lanjut',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () => controller.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false;
  bool agree = true;
  bool loading = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final nimController = TextEditingController();
  final universityController = TextEditingController();
  final facultyController = TextEditingController();
  final programController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (LabinBackend.client?.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openMain());
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    nimController.dispose();
    universityController.dispose();
    facultyController.dispose();
    programController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 22),
            const Center(child: LabinLogo(size: 76)),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Labin',
                style: titleStyle(context).copyWith(fontSize: 34),
              ),
            ),
            Center(
              child: Text(
                'Lab Smarter, Not Harder',
                style: mutedStyle(context),
              ),
            ),
            const SizedBox(height: 28),
            SegmentedSwitcher(
              labels: const ['Login', 'Register'],
              selectedIndex: register ? 1 : 0,
              onSelected: (index) => setState(() => register = index == 1),
            ),
            const SizedBox(height: 12),
            SupabaseConnectionBanner(configured: LabinBackend.initialized),
            const SizedBox(height: 18),
            if (!register) ...[
              AppTextField(
                label: 'Email / NIM',
                icon: Icons.person_outline_rounded,
                controller: emailController,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                trailing: Icons.visibility_outlined,
                obscureText: true,
                controller: passwordController,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Lupa Password?'),
                ),
              ),
              GradientButton(
                label: loading ? 'Menghubungkan...' : 'Login',
                icon: Icons.login_rounded,
                onPressed: loading ? null : _login,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('atau', style: mutedStyle(context)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: loading ? null : _loginWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Masuk dengan Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => register = true),
                  child: const Text('Belum punya akun? Daftar'),
                ),
              ),
            ] else ...[
              AppTextField(
                label: 'Nama lengkap',
                icon: Icons.badge_outlined,
                controller: nameController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'NIM / NPM',
                icon: Icons.confirmation_number_outlined,
                controller: nimController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email kampus',
                icon: Icons.mail_outline_rounded,
                controller: emailController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'University',
                icon: Icons.account_balance_outlined,
                controller: universityController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Faculty',
                icon: Icons.school_outlined,
                controller: facultyController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Study Program',
                icon: Icons.menu_book_outlined,
                controller: programController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Confirm Password',
                icon: Icons.verified_user_outlined,
                obscureText: true,
                controller: confirmPasswordController,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: agree,
                onChanged: (value) => setState(() => agree = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Saya menyetujui Syarat & Ketentuan Labin',
                  style: bodyStyle(context),
                ),
              ),
              GradientButton(
                label: loading ? 'Mendaftarkan...' : 'Daftar Sekarang',
                icon: Icons.arrow_forward_rounded,
                onPressed: agree && !loading ? _register : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!LabinBackend.initialized) {
      _showMessage(
        'Supabase belum dikonfigurasi. Isi LABIN_SUPABASE_URL dan LABIN_SUPABASE_PUBLISHABLE_KEY.',
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!_isValidEmail(email)) {
      _showMessage('Email belum valid.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('Password wajib diisi.');
      return;
    }

    await _runAuthAction(() async {
      await LabinBackend.client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _openMain();
    });
  }

  Future<void> _register() async {
    if (!LabinBackend.initialized) {
      _showMessage(
        'Supabase belum dikonfigurasi. Register hanya bisa berjalan setelah backend aktif.',
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final name = nameController.text.trim();
    final nim = nimController.text.trim();

    if (name.isEmpty || nim.isEmpty) {
      _showMessage('Nama lengkap dan NIM/NPM wajib diisi.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Email kampus belum valid.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Konfirmasi password belum sama.');
      return;
    }

    await _runAuthAction(() async {
      final response = await LabinBackend.client!.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'nim': nim,
          'university': universityController.text.trim(),
          'faculty': facultyController.text.trim(),
          'study_program': programController.text.trim(),
          'role': 'student',
        },
      );

      if (response.session != null) {
        _openMain();
        return;
      }

      setState(() => register = false);
      _showMessage(
        'Akun berhasil dibuat. Cek email untuk verifikasi, lalu login.',
      );
    });
  }

  Future<void> _loginWithGoogle() async {
    if (!LabinBackend.initialized) {
      _showMessage('Google OAuth butuh konfigurasi Supabase.');
      return;
    }

    await _runAuthAction(() async {
      await LabinBackend.client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.labin://login-callback/',
      );
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() => loading = true);
    try {
      await action();
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Gagal terhubung ke Supabase: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const LabScreen(),
      const ScheduleScreen(),
      ProfileScreen(
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: pages[tab],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _showQuickActions,
        backgroundColor: LabinTheme.primaryLight,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 78,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(
                color: LabinTheme.primary.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: tab == 0,
                onTap: () => setState(() => tab = 0),
              ),
              NavItem(
                icon: Icons.science_rounded,
                label: 'Lab',
                active: tab == 1,
                onTap: () => setState(() => tab = 1),
              ),
              const SizedBox(width: 54),
              NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal',
                active: tab == 2,
                onTap: () => setState(() => tab = 2),
              ),
              NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                active: tab == 3,
                onTap: () => setState(() => tab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mau ngapain hari ini?', style: titleStyle(context)),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .92,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                QuickAction(
                  icon: Icons.inventory_2_rounded,
                  label: 'Pinjam Alat',
                  route: '/loan',
                ),
                QuickAction(
                  icon: Icons.meeting_room_rounded,
                  label: 'Booking Ruangan',
                  route: '/reservation',
                ),
                QuickAction(
                  icon: Icons.construction_rounded,
                  label: 'Laporan',
                  route: '/report',
                ),
                QuickAction(
                  icon: Icons.campaign_rounded,
                  label: 'Pengumuman',
                  route: '/announcements',
                ),
                QuickAction(
                  icon: Icons.calendar_today_rounded,
                  label: 'Cek Jadwal',
                  onTap: () => setState(() => tab = 2),
                ),
                QuickAction(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
          children: [
            Row(
              children: [
                const LabinWordmark(),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    Positioned(
                      right: 6,
                      top: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: LabinTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  backgroundColor: LabinTheme.primary,
                  foregroundColor: Colors.white,
                  child: Text('RF'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GradientCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo, Rafi!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sabtu, 06 Juni 2026',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            GlassChip(
                              label: '2 Aktif',
                              icon: Icons.circle,
                              color: LabinTheme.accent,
                            ),
                            GlassChip(
                              label: '3 Tersedia',
                              icon: Icons.circle,
                              color: LabinTheme.success,
                            ),
                            GlassChip(
                              label: '1 Pending',
                              icon: Icons.circle,
                              color: LabinTheme.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const LabDeskIllustration(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Quick Actions',
              action: 'Lihat semua',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HomeAction(
                  icon: Icons.inventory_2_rounded,
                  title: 'Pinjam Alat',
                  subtitle: 'Ajukan peminjaman',
                  route: '/loan',
                ),
                HomeAction(
                  icon: Icons.calendar_month_rounded,
                  title: 'Reservasi',
                  subtitle: 'Booking ruangan lab',
                  route: '/reservation',
                ),
                HomeAction(
                  icon: Icons.build_circle_rounded,
                  title: 'Laporan',
                  subtitle: 'Laporkan kerusakan',
                  route: '/report',
                ),
                HomeAction(
                  icon: Icons.campaign_rounded,
                  title: 'Pengumuman',
                  subtitle: 'Info terbaru lab',
                  route: '/announcements',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Status Aktif',
              action: 'Detail',
              onAction: () => Navigator.pushNamed(context, '/tracking'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activeLoans.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) =>
                    ActiveLoanCard(loan: activeLoans[index]),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Slot Lab Hari Ini'),
            const SizedBox(height: 12),
            SizedBox(
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) => RoomSlotCard(room: rooms[index]),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Pengumuman Terbaru'),
            const SizedBox(height: 12),
            ...announcements
                .take(3)
                .map((item) => AnnouncementTile(item: item)),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Aktivitas Minggu Ini'),
            const SizedBox(height: 12),
            const WeekStrip(),
          ],
        ),
      ),
    );
  }
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  int category = 0;
  final categories = const [
    'Semua',
    'Komputer',
    'Studio',
    'Jaringan',
    'Multimedia',
    'Elektronika',
    'Alat Ukur',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'filter',
        onPressed: _showFilter,
        backgroundColor: LabinTheme.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.tune_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
          children: [
            Text('Lab', style: titleStyle(context).copyWith(fontSize: 28)),
            const SizedBox(height: 16),
            const AppTextField(
              label: 'Cari alat, ruangan, fasilitas...',
              icon: Icons.search_rounded,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ChoiceChip(
                  selected: category == index,
                  label: Text(categories[index]),
                  onSelected: (_) => setState(() => category = index),
                  selectedColor: LabinTheme.primaryLight,
                  labelStyle: TextStyle(
                    color: category == index ? Colors.white : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Featured Equipment'),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredEquipment.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) =>
                    FeaturedEquipmentCard(item: featuredEquipment[index]),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'All Equipment'),
            const SizedBox(height: 10),
            ...equipment.map((item) => EquipmentTile(item: item)),
          ],
        ),
      ),
    );
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Lab', style: titleStyle(context)),
            const SizedBox(height: 16),
            const Text('Availability'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                FilterChip(
                  label: Text('Tersedia'),
                  selected: true,
                  onSelected: null,
                ),
                FilterChip(
                  label: Text('Dipinjam'),
                  selected: false,
                  onSelected: null,
                ),
                FilterChip(
                  label: Text('Maintenance'),
                  selected: false,
                  onSelected: null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Terapkan Filter',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentDetailScreen extends StatelessWidget {
  const EquipmentDetailScreen({super.key, required this.item});

  final Equipment item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.colors,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Icon(
                        item.icon,
                        color: Colors.white.withValues(alpha: .18),
                        size: 210,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(
                            label: item.available ? 'Tersedia' : 'Dipinjam',
                            color: item.available
                                ? LabinTheme.success
                                : LabinTheme.danger,
                          ),
                          const SizedBox(width: 8),
                          Chip(label: Text(item.category)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(
                            child: StatCard(value: '3 unit', label: 'Stok'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: StatCard(value: '1 unit', label: 'Dipinjam'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: StatCard(value: 'Baik', label: 'Kondisi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Deskripsi', style: titleStyle(context)),
                      const SizedBox(height: 8),
                      Text(
                        '${item.specs}. Cocok untuk praktikum, penelitian, dan produksi konten lab. Gunakan sesuai SOP, simpan di tas pelindung, dan kembalikan sebelum pukul 17:00.',
                        style: bodyStyle(context).copyWith(height: 1.55),
                      ),
                      const SizedBox(height: 22),
                      Text('Availability Calendar', style: titleStyle(context)),
                      const SizedBox(height: 12),
                      const WeekStrip(compact: true),
                      const SizedBox(height: 22),
                      Text('History', style: titleStyle(context)),
                      const SizedBox(height: 8),
                      CardTile(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.history_rounded),
                          ),
                          title: const Text(
                            'Terakhir dipinjam oleh Naya Putri',
                          ),
                          subtitle: Text(
                            '2 hari lalu',
                            style: mutedStyle(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: LabinTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: LabinTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Pinjam Sekarang',
                        icon: Icons.inventory_2_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/loan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selected = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 94),
        child: FloatingActionButton.extended(
          heroTag: 'reservation',
          onPressed: () => Navigator.pushNamed(context, '/reservation'),
          label: const Text('Buat Reservasi'),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: LabinTheme.primaryLight,
          foregroundColor: Colors.white,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
          children: [
            Row(
              children: [
                Text(
                  'Jadwal Lab',
                  style: titleStyle(context).copyWith(fontSize: 28),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const Text(
                  'Juni 2026',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CardTile(
              child: GridView.builder(
                itemCount: 30,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, index) {
                  final day = index + 1;
                  final active = day == selected;
                  final event = [3, 6, 9, 14, 22, 28].contains(day);
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => selected = day),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? LabinTheme.primaryLight
                                : day == 6
                                ? LabinTheme.accent.withValues(alpha: .18)
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: active ? Colors.white : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: event
                                ? LabinTheme.primaryLight
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'Agenda $selected Juni'),
            const SizedBox(height: 12),
            ...agenda.map((event) => TimelineEvent(event: event)),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientBox(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LabinTheme.accent, width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        foregroundColor: LabinTheme.primary,
                        child: Text(
                          'RF',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rafi Aditya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2210511042',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const Text(
                      'Universitas Labin, FIK, Informatika',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const StatusPill(
                      label: 'Mahasiswa',
                      color: LabinTheme.accent,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Expanded(
                          child: GlassStat(
                            value: '12',
                            label: 'Total Pinjaman',
                            icon: Icons.inventory_2_rounded,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: GlassStat(
                            value: '10',
                            label: 'Selesai',
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: GlassStat(
                            value: '4.8',
                            label: 'Rating',
                            icon: Icons.star_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
            child: Column(
              children: [
                ProfileGroup(
                  title: 'Akun Saya',
                  children: [
                    ProfileItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profil',
                    ),
                    ProfileItem(
                      icon: Icons.school_outlined,
                      label: 'Data Akademik',
                    ),
                    ProfileItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Ubah Password',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Mode Gelap'),
                      value: darkMode,
                      onChanged: onThemeChanged,
                    ),
                  ],
                ),
                ProfileGroup(
                  title: 'Aktivitas',
                  children: [
                    ProfileItem(
                      icon: Icons.history_rounded,
                      label: 'Riwayat Peminjaman',
                      route: '/tracking',
                    ),
                    ProfileItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Reservasi Saya',
                    ),
                    ProfileItem(
                      icon: Icons.construction_rounded,
                      label: 'Laporan Saya',
                    ),
                    ProfileItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Favorit',
                    ),
                    ProfileItem(
                      icon: Icons.workspaces_outline,
                      label: 'Student Staff Portal',
                      route: '/staff',
                    ),
                  ],
                ),
                ProfileGroup(
                  title: 'Informasi',
                  children: [
                    ProfileItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang Labin',
                    ),
                    ProfileItem(
                      icon: Icons.article_outlined,
                      label: 'Syarat & Ketentuan',
                    ),
                    ProfileItem(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Kebijakan Privasi',
                    ),
                    ProfileItem(
                      icon: Icons.help_outline_rounded,
                      label: 'FAQ & Bantuan',
                    ),
                  ],
                ),
                ProfileGroup(
                  title: 'Lainnya',
                  children: [
                    ProfileItem(
                      icon: Icons.star_border_rounded,
                      label: 'Beri Rating Aplikasi',
                    ),
                    ProfileItem(
                      icon: Icons.logout_rounded,
                      label: 'Keluar',
                      danger: true,
                      onTap: () => _signOut(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (LabinBackend.initialized) {
      await LabinBackend.client!.auth.signOut();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }
}

class LoanFormScreen extends StatefulWidget {
  const LoanFormScreen({super.key});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  int step = 0;
  int amount = 1;
  bool agree = true;

  @override
  Widget build(BuildContext context) {
    return FlowScreen(
      title: 'Form Peminjaman',
      step: step,
      steps: const ['Pilih Alat', 'Isi Data', 'Konfirmasi'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step == 0) ...[
            EquipmentTile(item: equipment.first, compact: true),
            const SizedBox(height: 18),
            Text('Jumlah', style: titleStyle(context)),
            const SizedBox(height: 10),
            StepperControl(
              value: amount,
              onMinus: () => setState(() => amount = math.max(1, amount - 1)),
              onPlus: () => setState(() => amount++),
            ),
          ] else if (step == 1) ...[
            const AppTextField(
              label: 'Tanggal Pinjam',
              icon: Icons.calendar_today_rounded,
              value: '06 Juni 2026',
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Tanggal Kembali',
              icon: Icons.event_available_rounded,
              value: '10 Juni 2026',
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              text: 'Durasi otomatis: 4 hari',
              color: LabinTheme.accent,
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Keperluan',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DashedUploadCard(
              label: 'Upload KTM atau Surat Izin',
              uploaded: true,
            ),
          ] else ...[
            SummaryCard(
              items: {
                'Alat': equipment.first.name,
                'Jumlah': '$amount unit',
                'Tanggal': '06-10 Juni 2026',
                'Keperluan': 'Praktikum Multimedia',
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agree,
              onChanged: (value) => setState(() => agree = value ?? false),
              title: const Text(
                'Saya bertanggung jawab atas alat yang dipinjam',
              ),
            ),
            const InfoBanner(
              text: 'Estimasi respons: 1x24 jam',
              color: LabinTheme.warning,
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: step == 2 ? 'Kirim Permohonan' : 'Lanjut',
            icon: step == 2 ? Icons.send_rounded : Icons.arrow_forward_rounded,
            onPressed: step == 2 ? _success : () => setState(() => step++),
          ),
        ],
      ),
    );
  }

  void _success() {
    showDialog(
      context: context,
      builder: (_) => SuccessDialog(
        title: 'Permohonan Terkirim!',
        subtitle: 'Tracking ID: #LBN-20260606-042',
        primaryLabel: 'Pantau Status',
        onPrimary: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/tracking');
        },
      ),
    );
  }
}

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int step = 0;
  int attendees = 32;

  @override
  Widget build(BuildContext context) {
    return FlowScreen(
      title: 'Reservasi Ruangan',
      step: step,
      steps: const ['Ruangan', 'Waktu', 'Kegiatan', 'Konfirmasi'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step == 0)
            ...rooms.map((room) => RoomChoiceCard(room: room))
          else if (step == 1) ...[
            const AppTextField(
              label: 'Tanggal',
              icon: Icons.calendar_today_rounded,
              value: '07 Juni 2026',
            ),
            const SizedBox(height: 14),
            Text('Pilih Slot', style: titleStyle(context)),
            const SizedBox(height: 12),
            const TimeGrid(),
          ] else if (step == 2) ...[
            const AppTextField(
              label: 'Nama kegiatan',
              icon: Icons.title_rounded,
              value: 'Praktikum Pemrograman Mobile',
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Jenis kegiatan',
              icon: Icons.category_outlined,
              value: 'Praktikum',
            ),
            const SizedBox(height: 12),
            Text('Jumlah Peserta', style: titleStyle(context)),
            const SizedBox(height: 10),
            StepperControl(
              value: attendees,
              onMinus: () =>
                  setState(() => attendees = math.max(1, attendees - 1)),
              onPlus: () => setState(() => attendees++),
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Keterangan tambahan',
              icon: Icons.notes_rounded,
              maxLines: 4,
            ),
          ] else ...[
            SummaryCard(
              items: {
                'Ruangan': rooms.first.name,
                'Waktu': '07 Juni 2026, 09:00-11:00',
                'Kegiatan': 'Praktikum Pemrograman Mobile',
                'Peserta': '$attendees orang',
                'PIC': 'Rafi Aditya',
              },
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: step == 3 ? 'Ajukan Reservasi' : 'Lanjut',
            icon: Icons.arrow_forward_rounded,
            onPressed: step == 3 ? _success : () => setState(() => step++),
          ),
        ],
      ),
    );
  }

  void _success() {
    showDialog(
      context: context,
      builder: (_) => SuccessDialog(
        title: 'Reservasi Diajukan',
        subtitle: 'Lab Komputer A menunggu konfirmasi admin.',
        primaryLabel: 'Kembali',
        onPrimary: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    );
  }
}

class DamageReportScreen extends StatelessWidget {
  const DamageReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Laporan Kerusakan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
            text:
                'Temukan fasilitas rusak? Laporkan sekarang dan kami akan segera menangani.',
            color: LabinTheme.warning,
          ),
          const SizedBox(height: 16),
          const AppTextField(
            label: 'Lokasi',
            icon: Icons.place_outlined,
            value: 'Lab Komputer A',
          ),
          const SizedBox(height: 12),
          const AppTextField(
            label: 'Fasilitas rusak',
            icon: Icons.build_outlined,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tingkat urgensi',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const SegmentedSwitcher(
            labels: ['Rendah', 'Sedang', 'Tinggi', 'Kritis'],
            selectedIndex: 2,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            label: 'Deskripsi kerusakan',
            icon: Icons.edit_note_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          DashedUploadCard(label: 'Tambah foto kerusakan', uploaded: false),
          const SizedBox(height: 12),
          const AppTextField(
            label: 'Nama pelapor',
            icon: Icons.person_outline_rounded,
            value: 'Rafi Aditya',
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Kirim Laporan',
            icon: Icons.send_rounded,
            colors: const [LabinTheme.warning, Color(0xFFF97316)],
            onPressed: () => showDialog(
              context: context,
              builder: (_) => SuccessDialog(
                title: 'Laporan #RPT-042 diterima',
                subtitle: 'Tim kami akan merespons dalam 2x24 jam.',
                primaryLabel: 'Selesai',
                onPrimary: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Status & Tracking',
      child: Column(
        children: [
          const SegmentedSwitcher(
            labels: ['Aktif', 'Menunggu', 'Selesai', 'Ditolak'],
            selectedIndex: 0,
          ),
          const SizedBox(height: 16),
          ...trackingItems.map((item) => TrackingCard(item: item)),
        ],
      ),
    );
  }
}

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Pengumuman',
      child: Column(
        children: [
          const AppTextField(
            label: 'Cari pengumuman...',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 18),
          ...announcements.map(
            (item) => AnnouncementTile(item: item, large: item.pinned),
          ),
        ],
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Notifikasi',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('Tandai semua dibaca'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SegmentedSwitcher(
            labels: ['Semua', 'Peminjaman', 'Jadwal', 'Pengumuman', 'Sistem'],
            selectedIndex: 0,
          ),
          const SizedBox(height: 18),
          Text('Hari Ini', style: titleStyle(context)),
          const SizedBox(height: 10),
          ...notifications.map((item) => NotificationTile(item: item)),
        ],
      ),
    );
  }
}

class StaffPortalScreen extends StatelessWidget {
  const StaffPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Student Staff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientCard(
            child: Text(
              'Hei, Dion! Jadwal piket kamu hari ini: 13:00-17:00 Lab A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StaffAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Absen Masuk',
              ),
              StaffAction(icon: Icons.logout_rounded, label: 'Absen Pulang'),
              StaffAction(
                icon: Icons.assignment_rounded,
                label: 'Buat Laporan',
              ),
              StaffAction(icon: Icons.task_alt_rounded, label: 'Lihat Tugas'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Jadwal Piket', style: titleStyle(context)),
          const SizedBox(height: 10),
          ...agenda.map((event) => TimelineEvent(event: event)),
        ],
      ),
    );
  }
}

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: trailing == null ? null : [trailing!],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [child],
        ),
      ),
    );
  }
}

class FlowScreen extends StatelessWidget {
  const FlowScreen({
    super.key,
    required this.title,
    required this.step,
    required this.steps,
    required this.child,
  });

  final String title;
  final int step;
  final List<String> steps;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(step: step, labels: steps),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class LabinLogo extends StatelessWidget {
  const LabinLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: LabinTheme.primary,
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: [
          BoxShadow(
            color: LabinTheme.accent.withValues(alpha: .25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.science_rounded, color: Colors.white, size: size * .56),
          Positioned(
            right: size * .18,
            top: size * .18,
            child: Icon(
              Icons.wifi_rounded,
              color: Colors.white,
              size: size * .22,
            ),
          ),
        ],
      ),
    );
  }
}

class LabinWordmark extends StatelessWidget {
  const LabinWordmark({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color == Colors.white ? Colors.white24 : LabinTheme.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.science_rounded,
            color: color ?? Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Labin',
          style: TextStyle(
            color: color ?? LabinTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class GradientBox extends StatelessWidget {
  const GradientBox({
    super.key,
    required this.child,
    this.borderRadius,
    this.colors = const [
      LabinTheme.primary,
      LabinTheme.primaryLight,
      LabinTheme.accent,
    ],
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.colors = const [
      LabinTheme.primary,
      LabinTheme.primaryLight,
      LabinTheme.accent,
    ],
  });

  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.colors = const [LabinTheme.primaryLight, LabinTheme.accent],
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onPressed,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: .22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.trailing,
    this.obscureText = false,
    this.maxLines = 1,
    this.value,
    this.controller,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final bool obscureText;
  final int maxLines;
  final String? value;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      maxLines: maxLines,
      controller:
          controller ??
          (value == null ? null : TextEditingController(text: value)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: trailing == null ? null : Icon(trailing),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: .35),
          ),
        ),
      ),
    );
  }
}

class SupabaseConnectionBanner extends StatelessWidget {
  const SupabaseConnectionBanner({super.key, required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    final color = configured ? LabinTheme.success : LabinTheme.warning;
    final text = configured
        ? 'Backend Supabase aktif. Login dan register memakai akun asli.'
        : 'Backend belum aktif. Jalankan app dengan URL dan publishable key Supabase.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            configured ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: titleStyle(context)),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? LabinTheme.primaryLight : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? LabinTheme.primaryLight : Colors.grey,
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      onTap: () {
        Navigator.pop(context);
        if (route != null) {
          Navigator.pushNamed(context, route!);
        } else {
          onTap?.call();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: LabinTheme.primaryLight, size: 30),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class HomeAction extends StatelessWidget {
  const HomeAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: LabinTheme.primaryLight, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: mutedStyle(context).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveLoanCard extends StatelessWidget {
  const ActiveLoanCard({super.key, required this.loan});

  final ActiveLoan loan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      child: CardTile(
        onTap: () => Navigator.pushNamed(context, '/tracking'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(loan.icon, color: LabinTheme.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: loan.progress,
              color: LabinTheme.accent,
              backgroundColor: LabinTheme.accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
              minHeight: 8,
            ),
            const SizedBox(height: 10),
            Text(
              'Diajukan -> Disetujui -> Diambil -> Dikembalikan',
              style: mutedStyle(context).copyWith(fontSize: 11),
            ),
            const Spacer(),
            Row(
              children: [
                StatusPill(
                  label: loan.due,
                  color: loan.warning ? LabinTheme.warning : LabinTheme.success,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/tracking'),
                  child: const Text('Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoomSlotCard extends StatelessWidget {
  const RoomSlotCard({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 238,
      child: CardTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${room.capacity} kursi, ${room.floor}',
              style: mutedStyle(context).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: room.available,
              color: LabinTheme.success,
              backgroundColor: LabinTheme.success.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
              minHeight: 9,
            ),
            const SizedBox(height: 9),
            Text(
              'Tersedia ${room.slot}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/reservation'),
                child: const Text('Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedEquipmentCard extends StatelessWidget {
  const FeaturedEquipmentCard({super.key, required this.item});

  final Equipment item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 242,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EquipmentDetailScreen(item: item)),
        ),
        child: GradientCard(
          colors: item.colors,
          child: Stack(
            children: [
              Positioned(
                right: -16,
                bottom: -10,
                child: Icon(item.icon, size: 118, color: Colors.white24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    label: item.available ? 'Tersedia' : 'Dipinjam',
                    color: item.available
                        ? LabinTheme.success
                        : LabinTheme.danger,
                  ),
                  const Spacer(),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/loan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: LabinTheme.primary,
                    ),
                    child: const Text('Pinjam'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EquipmentTile extends StatelessWidget {
  const EquipmentTile({super.key, required this.item, this.compact = false});

  final Equipment item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      onTap: compact
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EquipmentDetailScreen(item: item),
              ),
            ),
      child: Row(
        children: [
          Container(
            width: compact ? 54 : 64,
            height: compact ? 54 : 64,
            decoration: BoxDecoration(
              color: item.colors.first.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.colors.first, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} - ${item.specs}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label: item.available ? 'Tersedia' : 'Dipinjam',
            color: item.available ? LabinTheme.success : LabinTheme.danger,
          ),
          if (!compact) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.item, this.large = false});

  final Announcement item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: large ? 52 : 42,
            height: large ? 52 : 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (item.pinned)
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: LabinTheme.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  maxLines: large ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      item.time,
                      style: mutedStyle(context).copyWith(fontSize: 11),
                    ),
                    if (item.newItem) ...[
                      const SizedBox(width: 8),
                      const StatusPill(
                        label: 'Baru',
                        color: LabinTheme.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return CardTile(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final today = index == 5;
          return Container(
            width: compact ? 38 : 42,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: today ? LabinTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    color: today ? Colors.white : null,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: today ? Colors.white : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: today ? Colors.white : LabinTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class TimelineEvent extends StatelessWidget {
  const TimelineEvent({super.key, required this.event});

  final AgendaEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            event.start,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 88,
              color: event.color.withValues(alpha: .25),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CardTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.room,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    StatusPill(label: event.status, color: event.color),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${event.start}-${event.end}', style: mutedStyle(context)),
                const SizedBox(height: 4),
                Text(
                  '${event.capacity}/40 kursi',
                  style: mutedStyle(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RoomChoiceCard extends StatelessWidget {
  const RoomChoiceCard({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LabinTheme.primaryLight, LabinTheme.accent],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${room.capacity} kursi - ${room.floor}',
                  style: mutedStyle(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    StatusPill(label: 'AC', color: LabinTheme.accent),
                    StatusPill(label: 'Proyektor', color: LabinTheme.success),
                    StatusPill(
                      label: 'Internet',
                      color: LabinTheme.primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: () {}, child: const Text('Pilih')),
        ],
      ),
    );
  }
}

class TimeGrid extends StatelessWidget {
  const TimeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = ['07', '08', '09', '10', '11', '12', '13', '14', '15', '16'];
    return GridView.builder(
      itemCount: slots.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (_, index) {
        final booked = [1, 4, 5].contains(index);
        final selected = [2, 3].contains(index);
        final color = selected
            ? LabinTheme.primaryLight
            : booked
            ? LabinTheme.danger
            : LabinTheme.success;
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 1 : .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${slots[index]}:00',
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: active
                            ? LabinTheme.primaryLight
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? LabinTheme.primaryLight
                          : Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? LabinTheme.primaryLight
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (index < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < step
                            ? LabinTheme.primaryLight
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 54,
            child: Center(child: Text('$value', style: titleStyle(context))),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}

class DashedUploadCard extends StatelessWidget {
  const DashedUploadCard({
    super.key,
    required this.label,
    required this.uploaded,
  });

  final String label;
  final bool uploaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LabinTheme.accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LabinTheme.accent.withValues(alpha: .5),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Icon(
            uploaded
                ? Icons.insert_drive_file_rounded
                : Icons.add_photo_alternate_outlined,
            color: LabinTheme.accent,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            uploaded ? 'ktm_rafi.pdf' : label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            uploaded ? 'File siap dikirim' : 'Tap untuk menambahkan file',
            style: mutedStyle(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.items});

  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Column(
        children: items.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(entry.key, style: mutedStyle(context)),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            tween: Tween(begin: .2, end: 1),
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: const CircleAvatar(
              radius: 42,
              backgroundColor: LabinTheme.success,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: titleStyle(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: mutedStyle(context),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: primaryLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }
}

class SegmentedSwitcher extends StatelessWidget {
  const SegmentedSwitcher({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .3),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? LabinTheme.primaryLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w900,
                    fontSize: labels.length > 4 ? 11 : 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: mutedStyle(context).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class GlassStat extends StatelessWidget {
  const GlassStat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class ProfileGroup extends StatelessWidget {
  const ProfileGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: mutedStyle(context).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  const ProfileItem({
    super.key,
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? LabinTheme.danger : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap:
          onTap ??
          (route == null ? () {} : () => Navigator.pushNamed(context, route!)),
    );
  }
}

class TrackingCard extends StatelessWidget {
  const TrackingCard({super.key, required this.item});

  final TrackingItem item;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: CircleAvatar(
          backgroundColor: item.color.withValues(alpha: .12),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(item.date, style: mutedStyle(context)),
        trailing: StatusPill(label: item.status, color: item.color),
        children: [
          ...item.steps.map(
            (step) => ListTile(
              dense: true,
              leading: Icon(
                step.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: step.done ? LabinTheme.success : Colors.grey,
              ),
              title: Text(step.label),
              subtitle: Text(
                step.time,
                style: mutedStyle(context).copyWith(fontSize: 12),
              ),
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: LabinTheme.danger,
                ),
                child: const Text('Batalkan'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Konfirmasi Pengambilan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.color.withValues(alpha: .12),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: mutedStyle(context).copyWith(fontSize: 11),
              ),
              const SizedBox(height: 8),
              if (item.unread)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: LabinTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaffAction extends StatelessWidget {
  const StaffAction({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CardTile(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: LabinTheme.primaryLight, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class LabIllustration extends StatelessWidget {
  const LabIllustration({super.key, required this.icon, required this.page});

  final IconData icon;
  final int page;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(52),
              border: Border.all(color: Colors.white24),
            ),
          ),
          Icon(icon, color: Colors.white, size: 104),
          Positioned(
            right: 24,
            top: 34,
            child: FloatingDot(size: 30 + page * 4),
          ),
          const Positioned(left: 28, bottom: 46, child: FloatingDot(size: 22)),
        ],
      ),
    );
  }
}

class FloatingDot extends StatelessWidget {
  const FloatingDot({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

class LabDeskIllustration extends StatelessWidget {
  const LabDeskIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 12,
            child: Container(
              width: 78,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const Positioned(
            top: 12,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 54),
          ),
          const Positioned(
            bottom: 32,
            right: 12,
            child: Icon(Icons.science_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

TextStyle titleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge!.copyWith(
    fontWeight: FontWeight.w900,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

TextStyle bodyStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium!.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  );
}

TextStyle mutedStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall!.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58),
  );
}

class OnboardData {
  const OnboardData({
    required this.title,
    required this.body,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Color> colors;
}

class Equipment {
  const Equipment({
    required this.name,
    required this.category,
    required this.specs,
    required this.available,
    required this.icon,
    required this.colors,
  });

  final String name;
  final String category;
  final String specs;
  final bool available;
  final IconData icon;
  final List<Color> colors;
}

class ActiveLoan {
  const ActiveLoan({
    required this.name,
    required this.icon,
    required this.progress,
    required this.due,
    required this.warning,
  });

  final String name;
  final IconData icon;
  final double progress;
  final String due;
  final bool warning;
}

class Room {
  const Room({
    required this.name,
    required this.capacity,
    required this.floor,
    required this.available,
    required this.slot,
  });

  final String name;
  final int capacity;
  final String floor;
  final double available;
  final String slot;
}

class Announcement {
  const Announcement({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.pinned = false,
    this.newItem = false,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool pinned;
  final bool newItem;
}

class AgendaEvent {
  const AgendaEvent({
    required this.room,
    required this.start,
    required this.end,
    required this.status,
    required this.capacity,
    required this.color,
  });

  final String room;
  final String start;
  final String end;
  final String status;
  final int capacity;
  final Color color;
}

class TrackingItem {
  const TrackingItem({
    required this.title,
    required this.date,
    required this.status,
    required this.icon,
    required this.color,
    required this.steps,
  });

  final String title;
  final String date;
  final String status;
  final IconData icon;
  final Color color;
  final List<TrackingStep> steps;
}

class TrackingStep {
  const TrackingStep({
    required this.label,
    required this.time,
    required this.done,
  });

  final String label;
  final String time;
  final bool done;
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.unread,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool unread;
}

const equipment = [
  Equipment(
    name: 'Kamera DSLR Canon EOS 90D',
    category: 'Studio',
    specs: '32MP, 4K video',
    available: true,
    icon: Icons.photo_camera_rounded,
    colors: [Color(0xFF7C3AED), LabinTheme.accent],
  ),
  Equipment(
    name: 'Router MikroTik RB951',
    category: 'Jaringan',
    specs: '5 port ethernet',
    available: true,
    icon: Icons.router_rounded,
    colors: [LabinTheme.primaryLight, Color(0xFF14B8A6)],
  ),
  Equipment(
    name: 'Oscilloscope Digital',
    category: 'Alat Ukur',
    specs: '100MHz, dual channel',
    available: false,
    icon: Icons.monitor_heart_rounded,
    colors: [Color(0xFFF97316), LabinTheme.warning],
  ),
  Equipment(
    name: 'Laptop Praktikum Dell',
    category: 'Komputer',
    specs: 'Core i7, 16GB RAM',
    available: true,
    icon: Icons.laptop_mac_rounded,
    colors: [LabinTheme.primary, LabinTheme.primaryLight],
  ),
];

final featuredEquipment = [equipment[0], equipment[1], equipment[3]];

const activeLoans = [
  ActiveLoan(
    name: 'Kamera DSLR Canon EOS 90D',
    icon: Icons.photo_camera_rounded,
    progress: .68,
    due: 'Kembali 10 Jun',
    warning: true,
  ),
  ActiveLoan(
    name: 'Router MikroTik RB951',
    icon: Icons.router_rounded,
    progress: .36,
    due: 'Disetujui',
    warning: false,
  ),
];

const rooms = [
  Room(
    name: 'Lab Komputer A',
    capacity: 40,
    floor: 'Gedung B Lt. 2',
    available: .72,
    slot: '13:00-15:00',
  ),
  Room(
    name: 'Lab Studio',
    capacity: 24,
    floor: 'Gedung C Lt. 1',
    available: .48,
    slot: '15:00-17:00',
  ),
  Room(
    name: 'Lab Jaringan',
    capacity: 32,
    floor: 'Gedung B Lt. 3',
    available: .64,
    slot: '09:00-11:00',
  ),
];

const announcements = [
  Announcement(
    title: 'Maintenance Lab Studio 7-9 Juni',
    body:
        'Lab Studio ditutup sementara untuk perawatan perangkat audio visual.',
    time: '2 jam lalu',
    icon: Icons.build_rounded,
    color: LabinTheme.warning,
    pinned: true,
    newItem: true,
  ),
  Announcement(
    title: 'Rekrutmen Student Staff Dibuka',
    body: 'Daftar sebelum 15 Juni 2026 dan bantu operasional lab kampus.',
    time: '1 hari lalu',
    icon: Icons.groups_rounded,
    color: LabinTheme.accent,
    newItem: true,
  ),
  Announcement(
    title: 'SOP Peminjaman Alat Diperbarui',
    body:
        'Mahasiswa wajib mengunggah KTM dan surat izin untuk alat bernilai tinggi.',
    time: '3 hari lalu',
    icon: Icons.campaign_rounded,
    color: LabinTheme.primaryLight,
  ),
];

const agenda = [
  AgendaEvent(
    room: 'Lab Komputer A',
    start: '07:00',
    end: '09:00',
    status: 'Selesai',
    capacity: 36,
    color: LabinTheme.success,
  ),
  AgendaEvent(
    room: 'Lab Jaringan',
    start: '09:00',
    end: '11:00',
    status: 'Berlangsung',
    capacity: 32,
    color: LabinTheme.accent,
  ),
  AgendaEvent(
    room: 'Lab Studio',
    start: '13:00',
    end: '15:00',
    status: 'Akan Datang',
    capacity: 18,
    color: LabinTheme.primaryLight,
  ),
];

const trackingItems = [
  TrackingItem(
    title: 'Kamera DSLR Canon EOS 90D',
    date: '06 Jun 2026',
    status: 'Disetujui',
    icon: Icons.inventory_2_rounded,
    color: LabinTheme.success,
    steps: [
      TrackingStep(
        label: 'Permohonan Dikirim',
        time: '06 Jun 10:32',
        done: true,
      ),
      TrackingStep(
        label: 'Diverifikasi Admin',
        time: '06 Jun 14:00',
        done: true,
      ),
      TrackingStep(label: 'Serah Terima', time: 'Belum', done: false),
      TrackingStep(label: 'Dikembalikan', time: 'Belum', done: false),
    ],
  ),
  TrackingItem(
    title: 'Lab Komputer A',
    date: '07 Jun 2026',
    status: 'Menunggu',
    icon: Icons.meeting_room_rounded,
    color: LabinTheme.warning,
    steps: [
      TrackingStep(
        label: 'Reservasi Dikirim',
        time: '06 Jun 11:10',
        done: true,
      ),
      TrackingStep(label: 'Review Admin', time: 'Belum', done: false),
      TrackingStep(label: 'Dikonfirmasi', time: 'Belum', done: false),
    ],
  ),
];

const notifications = [
  AppNotification(
    title: 'Peminjaman Disetujui',
    message: 'Kamera DSLR siap diambil di Lab Studio',
    time: '2 jam',
    icon: Icons.check_circle_rounded,
    color: LabinTheme.success,
    unread: true,
  ),
  AppNotification(
    title: 'Reminder Pengembalian',
    message: 'Alat harus dikembalikan besok pukul 17:00',
    time: '5 jam',
    icon: Icons.alarm_rounded,
    color: LabinTheme.warning,
    unread: true,
  ),
  AppNotification(
    title: 'Reservasi Dikonfirmasi',
    message: 'Lab Komputer B - 07 Jun 09:00-11:00',
    time: '1 hari',
    icon: Icons.calendar_month_rounded,
    color: LabinTheme.accent,
    unread: false,
  ),
  AppNotification(
    title: 'Maintenance Terjadwal',
    message: 'Lab Studio ditutup 7-9 Juni untuk pemeliharaan',
    time: '2 hari',
    icon: Icons.warning_rounded,
    color: LabinTheme.danger,
    unread: false,
  ),
];
