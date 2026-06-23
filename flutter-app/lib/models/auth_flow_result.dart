enum AuthFormMode { signIn, signUp }

/// Result of a sign-up attempt — separates success, email pending, and errors.
class SignUpResult {  const SignUpResult._({
    required this.status,
    this.message,
  });

  const SignUpResult.success() : this._(status: SignUpStatus.success);

  const SignUpResult.pendingEmail({String? message})
      : this._(
          status: SignUpStatus.pendingEmail,
          message: message,
        );

  const SignUpResult.failed(String message)
      : this._(status: SignUpStatus.failed, message: message);

  final SignUpStatus status;
  final String? message;

  bool get isSuccess => status == SignUpStatus.success;
  bool get isPendingEmail => status == SignUpStatus.pendingEmail;
}

enum SignUpStatus { success, pendingEmail, failed }
