# AssetFlow

AssetFlow is a comprehensive Flutter application designed to help clients track and manage their real estate investments and other assets effectively.

## Features

- **User Authentication**: Secure sign-in, sign-up, and password reset functionality
- **Investment Dashboard**: View all your investments at a glance
- **Investment Details**: Deep dive into specifics of each investment
- **Multiple Investment Plans**: Support for different investment structures within a project
- **Investment Wizard**: Step-by-step process for adding new investments
- **Fee Management**: Track both refundable and non-refundable fees
- **Payment Tracking**: Monitor payment schedules and distributions

## Getting Started

### Prerequisites

- Flutter SDK (Version 3.0.0 or higher)
- Dart SDK (Version 3.0.0 or higher)
- Firebase account

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android, iOS, and/or Web apps to your Firebase project
3. Download the configuration files:
   - For Android: `google-services.json`
   - For iOS: `GoogleService-Info.plist`
   - For Web: Firebase config object
4. Copy `firebase_options.template.dart` to `firebase_options.dart` and update it with your Firebase configuration

### Installation

1. Clone the repository
   ```
   git clone https://github.com/vbar20230812/asset_flow.git
   cd asset_flow
   ```

2. Install dependencies
   ```
   flutter pub get
   ```

3. Run the app
   ```
   flutter run
   ```

## Project Structure

The project follows a modular structure:

- `auth/`: Authentication related screens and services
- `list/`: Asset listing and details
- `models/`: Data models and structures
- `new/`: New investment wizard
- `services/`: Firebase and other services
- `utils/`: Utility functions and helpers
- `widgets/`: Reusable custom widgets

## Firebase Collections

The app uses the following Firestore collection structure:

```
users/
  {userId}/
    projects/
      {projectId}/
        plans/
          {planId}/
```

## Development Guidelines

- Use the Logger utility for all logging
- Follow the established color scheme in `theme_colors.dart`
- Split large widgets into separate files
- Create reusable components in the widgets directory
- Add appropriate documentation for public methods and classes
- Run tests before committing changes

## Security

- Firebase Authentication handles user authentication securely
- Firebase security rules should be set up to restrict access to user data
- Sensitive values should not be hardcoded
- API keys and Firebase configuration should not be committed to the repository

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter and Firebase for making app development accessible
- The client for their insightful feedback and requirements