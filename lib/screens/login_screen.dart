import 'package:adisyon_uygulamasi/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adisyon_uygulamasi/main.dart';
import '../widgets/shared/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _selectedRole = 'Garson';
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _roles = ['Garson', 'Mutfak', 'Kasiyer', 'Yönetici'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
        // Rol parametresini normalize et: yönetici için diakritik kaldırılıyor
        final rolParam = _selectedRole == 'Yönetici' ? 'yonetici' : _selectedRole.toLowerCase();
        // Şifreyi normalize et: Türkçe karakterleri ASCII'ye çevir
        final rawSifre = _passwordController.text.trim();
        final normalizedSifre = rawSifre
          .replaceAll('ö', 'o').replaceAll('Ö', 'O')
          .replaceAll('ü', 'u').replaceAll('Ü', 'U')
          .replaceAll('ş', 's').replaceAll('Ş', 'S')
          .replaceAll('ç', 'c').replaceAll('Ç', 'C')
          .replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
          .replaceAll('ı', 'i').replaceAll('İ', 'I');
        final result = await supabase.rpc('kullanici_giris', params: {
          'p_rol': rolParam,
          'p_sifre': normalizedSifre,
        });

        if (mounted && result != null) {
          final userRole = result['rol'];
          
          await supabase.rpc('set_current_role', params: {'p_role': userRole});

          Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
              builder: (context) => HomeScreen(userRole: userRole),
        ),
        (route) => false,
      );
        } else if (mounted) {
          _showError('Seçilen rol veya şifre hatalı.');
        }
    } catch (e) {
        if (mounted) {
          _showError('Giriş yapılırken bir veritabanı hatası oluştu: ${e.toString()}');
        }
    } finally {
      if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Color _textColor(BuildContext context, [double opacity = 1]) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    return onBg.withOpacity(opacity);
  }

  Color _cardColor(BuildContext context, double opacityDark, double opacityLight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.black).withOpacity(isDark ? opacityDark : opacityLight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 16,
            right: 16,
            child: ThemeToggleButton(),
          ),
          // Şeffaf gradient overlay ile tasarım
          Positioned.fill(
            child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
                  colors: [
                    Color(0xFF2C3E50).withOpacity(0.6),
                    Color(0xFF4A69BD).withOpacity(0.6)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
            ),
          ),
          SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
              : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo ve Başlık
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _cardColor(context, 0.15, 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'logo.png',
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'ADISYON SİSTEMİ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onBackground,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lütfen rolünüzü seçin ve şifrenizi girin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: _textColor(context, 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),

                                // Rol Seçim Kartları
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _cardColor(context, 0.1, 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _cardColor(context, 0.2, 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ROL SEÇİN',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textColor(context, 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Rol Seçenekleri
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _buildRoleOption('Garson', Icons.person_outline),
                                          _buildRoleOption('Mutfak', Icons.kitchen_outlined),
                                          _buildRoleOption('Kasiyer', Icons.point_of_sale_outlined),
                                          _buildRoleOption('Yönetici', Icons.admin_panel_settings_outlined),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Şifre Girişi
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _cardColor(context, 0.1, 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _cardColor(context, 0.2, 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ŞİFRENİZ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textColor(context, 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Şifre girin',
                                          hintStyle: GoogleFonts.poppins(color: Colors.white38),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.white60,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen şifrenizi girin';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (_) => _login(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Giriş Butonu
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black54,
                                            ),
                                          )
                                        : Text(
                                            'GİRİŞ YAP',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                          ),
                        ),
                      ),
                    ],
      ),
    );
  }

  Widget _buildRoleOption(String role, IconData icon) {
    final bool isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.amber 
              : _cardColor(context, 0.1, 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.amber.shade700 
                : _cardColor(context, 0.2, 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black87 : _textColor(context, 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              role,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black87 : _textColor(context, 0.7),
            ),
            ),
          ],
        ),
      ),
    );
  }
} 