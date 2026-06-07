import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_theme.dart';

class LoginScreen extends StatefulWidget {
  final GameTheme currentTheme;

  const LoginScreen({super.key, required this.currentTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) {
          return;
        }

        if (response.session == null) {
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _isSignUp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dang ki thanh cong. Hay kiem tra email xac thuc.'),
            ),
          );
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _isSignUp
            ? 'Khong the dang ki. Vui long thu lai.'
            : 'Khong the dang nhap. Vui long thu lai.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    var isLoading = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
              });

              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(
                  emailController.text.trim(),
                );
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Da gui email dat lai mat khau.'),
                  ),
                );
              } on AuthException catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }
                setDialogState(() {
                  errorMessage = error.message;
                });
              } catch (_) {
                if (!dialogContext.mounted) {
                  return;
                }
                setDialogState(() {
                  errorMessage =
                      'Khong the gui email dat lai mat khau. Vui long thu lai.';
                });
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: widget.currentTheme.cardBg,
              title: Text(
                'Quen mat khau',
                style: TextStyle(
                  color: widget.currentTheme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nhap email de nhan lien ket dat lai mat khau.',
                      style: TextStyle(color: widget.currentTheme.subTextColor),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Nhap email';
                        }
                        if (!email.contains('@')) {
                          return 'Email khong hop le';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => submit(),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Huy'),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Gui email'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.currentTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.gridLineColor.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.grid_4x4, color: theme.xColor, size: 44),
                        const SizedBox(height: 16),
                        Text(
                          _isSignUp ? 'Dang ki Caro' : 'Dang nhap Caro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Nhap email';
                            }
                            if (!email.contains('@')) {
                              return 'Email khong hop le';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submitAuthForm(),
                          decoration: InputDecoration(
                            labelText: 'Mat khau',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hien mat khau'
                                  : 'An mat khau',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return 'Nhap mat khau';
                            }
                            if (_isSignUp && password.length < 6) {
                              return 'Mat khau toi thieu 6 ky tu';
                            }
                            return null;
                          },
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submitAuthForm(),
                            decoration: const InputDecoration(
                              labelText: 'Nhap lai mat khau',
                              prefixIcon: Icon(Icons.lock_reset),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Mat khau nhap lai khong khop';
                              }
                              return null;
                            },
                          ),
                        ] else
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _showForgotPasswordDialog,
                              child: const Text('Quen mat khau?'),
                            ),
                          ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submitAuthForm,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isSignUp ? Icons.person_add : Icons.login,
                                ),
                          label: Text(
                            _isLoading
                                ? (_isSignUp ? 'Dang ki...' : 'Dang nhap...')
                                : (_isSignUp ? 'Dang ki' : 'Dang nhap'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.xColor,
                            foregroundColor:
                                ThemeData.estimateBrightnessForColor(
                                      theme.xColor,
                                    ) ==
                                    Brightness.light
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading ? null : _toggleAuthMode,
                          child: Text(
                            _isSignUp
                                ? 'Da co tai khoan? Dang nhap'
                                : 'Chua co tai khoan? Dang ki',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
