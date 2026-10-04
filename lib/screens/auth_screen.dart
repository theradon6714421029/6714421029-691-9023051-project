import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool isRegister = false;
  bool loading = false;
  String? errorMessage;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกอีเมลและรหัสผ่าน';
      });
      return;
    }

    if (isRegister && name.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกชื่อ';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      if (isRegister) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user!;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': email,
          'displayName': name,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.updateDisplayName(name);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด';

      switch (e.code) {
        case 'invalid-email':
          message = 'อีเมลไม่ถูกต้อง';
          break;
        case 'user-not-found':
          message = 'ไม่พบบัญชีนี้';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
          break;
        case 'email-already-in-use':
          message = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'weak-password':
          message = 'รหัสผ่านสั้นเกินไป';
          break;
        default:
          message = e.message ?? 'เกิดข้อผิดพลาด';
      }

      setState(() {
        errorMessage = message;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRegister ? 'สร้างบัญชี' : 'เข้าสู่ระบบ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isRegister) ...[
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: loading ? null : submit,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isRegister
                                    ? 'สมัครสมาชิก'
                                    : 'เข้าสู่ระบบ',
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              setState(() {
                                isRegister = !isRegister;
                                errorMessage = null;
                              });
                            },
                      child: Text(
                        isRegister
                            ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                            : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                      ),
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
}