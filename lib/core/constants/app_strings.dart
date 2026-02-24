/// App-wide string constants for CARE-AI.
class AppStrings {
  AppStrings._();

  static const String appName = 'CARE-AI';
  static const String tagline = 'Empowering Parents. Supporting Every Child.';

  // Auth
  static const String login = 'Log In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? ";
  static const String hasAccount = 'Already have an account? ';
  static const String loginSuccess = 'Logged in successfully!';
  static const String signUpSuccess = 'Account created successfully!';

  // Profile
  static const String profileSetup = 'Child Profile Setup';
  static const String childName = 'Child\'s Name';
  static const String childAge = 'Child\'s Age';
  static const String condition = 'Condition / Diagnosis';
  static const String communicationLevel = 'Communication Level';
  static const String challenges = 'Behavioral Challenges';
  static const String parentGoals = 'Parent Goals';
  static const String saveProfile = 'Save Profile';

  // Home
  static const String askAi = 'Ask AI';
  static const String activities = 'Activities';
  static const String progress = 'Progress';
  static const String profile = 'Profile';

  // Chat
  static const String chatTitle = 'AI Assistant';
  static const String typeMessage = 'Type your message...';

  // Disclaimer
  static const String disclaimer =
      'CARE-AI does not provide medical diagnoses. '
      'Always consult a qualified professional for medical advice.';

  // Communication Levels
  static const List<String> communicationLevels = [
    'Non-verbal',
    'Limited words',
    'Phrases',
    'Full sentences',
    'Age-appropriate',
  ];

  // Common Conditions
  static const List<String> commonConditions = [
    'Autism Spectrum Disorder (ASD)',
    'ADHD',
    'Speech Delay',
    'Cerebral Palsy',
    'Down Syndrome',
    'Learning Disability',
    'Sensory Processing Disorder',
    'Other',
  ];
}
