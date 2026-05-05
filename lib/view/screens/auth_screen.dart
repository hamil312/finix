// filepath: lib\view\screens\auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;
  final _formKey = GlobalKey<FormState>();
  
  late String _email;
  late String _password;
  late String _confirmPassword;
  late String _name;
  late String _currency;
  late double _monthlyIncome;

  @override
  void initState() {
    super.initState();
    _currency = 'USD';
    _monthlyIncome = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo/Título
                    Icon(
                      Icons.trending_up,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FinanzApp',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginMode
                          ? 'Inicia sesión en tu cuenta'
                          : 'Crea una nueva cuenta',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Formulario
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLoginMode) ...[
                            // Campo Nombre
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                              onSaved: (value) => _name = value ?? '',
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Campo Email
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!value.contains('@')) {
                                return 'Email no válido';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value ?? '',
                          ),
                          const SizedBox(height: 16),

                          // Campo Contraseña
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value ?? '',
                          ),
                          const SizedBox(height: 16),

                          // Confirmar Contraseña (solo en registro)
                          if (!_isLoginMode)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirmar Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirmar contraseña es requerido';
                                }
                                return null;
                              },
                              onSaved: (value) =>
                                  _confirmPassword = value ?? '',
                            ),
                          if (!_isLoginMode) const SizedBox(height: 16),

                          // Moneda (solo en registro)
                          if (!_isLoginMode)
                            DropdownButtonFormField<String>(
                              value: _currency,
                              decoration: InputDecoration(
                                labelText: 'Moneda',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: ['USD', 'EUR', 'COP', 'MXN', 'ARS']
                                  .map((currency) =>
                                      DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _currency = value);
                                }
                              },
                            ),
                          if (!_isLoginMode) const SizedBox(height: 16),

                          // Ingreso Mensual (solo en registro)
                          if (!_isLoginMode)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Ingreso Mensual (opcional)',
                                prefixIcon: const Icon(Icons.monetization_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                _monthlyIncome =
                                    double.tryParse(value ?? '0') ?? 0;
                              },
                            ),
                          if (!_isLoginMode) const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Mensaje de error
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (authProvider.error != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                authProvider.error!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Botón Principal
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleSubmit(context),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Enlace para cambiar modo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode
                              ? '¿No tienes cuenta?'
                              : '¿Ya tienes cuenta?',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              _formKey.currentState?.reset();
                            });
                            context.read<AuthProvider>().clearError();
                          },
                          child: Text(
                            _isLoginMode ? 'Registrarse' : 'Iniciar Sesión',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final authProvider = context.read<AuthProvider>();

    if (_isLoginMode) {
      authProvider.login(email: _email, password: _password);
    } else {
      authProvider.register(
        name: _name,
        email: _email,
        password: _password,
        confirmPassword: _confirmPassword,
        currency: _currency,
        monthlyIncome: _monthlyIncome,
      );
    }
  }
}