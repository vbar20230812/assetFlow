# AssetFlow Application Structure

```
asset_flow/
│
├── android/                   # Android specific files
├── ios/                       # iOS specific files
├── web/                       # Web specific files
│
├── lib/                       # Dart source code
│   ├── main.dart              # Entry point of the application
│   │
│   ├── auth/                  # Authentication related files
│   │   ├── auth_screen.dart
│   │   ├── auth_service.dart
│   │   ├── auth_wrapper.dart
│   │   ├── signup_screen.dart
│   │   └── forgot_password_screen.dart
│   │
│   ├── list/                  # Asset listing related files
│   │   ├── assets_list_screen.dart
│   │   ├── asset_detail_screen.dart
│   │   └── empty_assets_screen.dart
│   │
│   ├── models/                # Data models
│   │   ├── asset.dart
│   │   ├── plan.dart
│   │   └── project.dart
│   │
│   ├── new/                   # New investment wizard
│   │   ├── add_investment_screen.dart
│   │   └── steps/
│   │       ├── project_step.dart
│   │       ├── plan_step.dart
│   │       ├── amount_step.dart
│   │       └── fees_step.dart
│   │
│   ├── services/              # Firebase and other services
│   │   └── database_service.dart
│   │
│   ├── start/                 # Splash screen and onboarding
│   │   └── splash_screen.dart
│   │
│   ├── utils/                 # Utilities and helper functions
│   │   ├── date_util.dart
│   │   ├── formatter_util.dart
│   │   ├── logger_util.dart
│   │   └── theme_colors.dart
│   │
│   └── widgets/               # Reusable widgets
│       ├── asset_flow_loader.dart
│       └── asset_flow_loading_widget.dart
│
├── assets/                    # App assets
│   ├── images/                # Image files
│   └── fonts/                 # Font files
│
├── test/                      # Unit and widget tests
│
├── pubspec.yaml               # Dependencies and package info
├── firebase_options.dart      # Firebase configuration (not in git)
├── firebase_options.template.dart # Template for Firebase config
└── README.md                  # Project documentation
```

## Key Files Description

### Main Files
- **main.dart**: Application entry point, sets up Firebase and initializes the app
- **firebase_options.dart**: Firebase configuration (not in git)
- **firebase_options.template.dart**: Template for Firebase configuration

### Auth Module
- **auth_service.dart**: Firebase authentication service
- **auth_wrapper.dart**: Manages authentication state
- **auth_screen.dart**: Sign-in screen
- **signup_screen.dart**: Sign-up screen
- **forgot_password_screen.dart**: Password reset screen

### List Module
- **assets_list_screen.dart**: Lists all user investments
- **asset_detail_screen.dart**: Detailed view of a specific investment
- **empty_assets_screen.dart**: Shown when the user has no investments

### Models
- **project.dart**: Represents a real estate project
- **plan.dart**: Represents an investment plan within a project
- **asset.dart**: Represents a specific investment made by the user

### New Investment Wizard
- **add_investment_screen.dart**: Main wizard container
- **project_step.dart**: Step for project information
- **plan_step.dart**: Step for investment plans
- **amount_step.dart**: Step for investment amount and dates
- **fees_step.dart**: Step for fees

### Services
- **database_service.dart**: Firebase Firestore operations

### Utilities
- **date_util.dart**: Date formatting and calculations
- **formatter_util.dart**: Currency and number formatting
- **logger_util.dart**: Logging configuration
- **theme_colors.dart**: App color scheme

### Widgets
- **asset_flow_loader.dart**: Custom loader animation
- **asset_flow_loading_widget.dart**: Loading overlay widget