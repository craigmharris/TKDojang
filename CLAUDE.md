# Claude Code Configuration

This file provides context and instructions for Claude Code when working on this project.

## Project Overview

This is **TKDojang**, a Taekwondo learning iOS app built with SwiftUI using the MVVM-C (Model-View-ViewModel-Coordinator) architecture pattern. The app is designed to help users learn Taekwondo from beginner to advanced levels with structured lessons, technique demonstrations, and progress tracking.

## Architecture & Patterns

- **MVVM-C Architecture**: Model-View-ViewModel-Coordinator pattern for clean separation of concerns
- **Feature-based Organization**: Code is organized by features rather than file types
- **Protocol-Oriented Programming**: Heavy use of protocols for dependency injection and testability
- **Reactive Programming**: Uses Combine framework for reactive data flow
- **SwiftUI**: Modern declarative UI framework

## Key Conventions

### Code Style
- **Comprehensive Documentation**: Every public interface must include detailed documentation explaining WHY decisions were made
- **Descriptive Naming**: Use clear, self-documenting variable and function names
- **Single Responsibility**: Each file/class should have one clear purpose
- **No Magic Numbers**: Use constants from `AppConstants.swift`

### File Organization
- Features are organized in `/Sources/Features/[FeatureName]/`
- Shared code goes in `/Sources/Core/`
- Each feature should have its own coordinator for navigation
- Models and utilities are centralized in `/Sources/Core/Utils/`

### Testing
- Unit tests for business logic and utilities
- UI tests for critical user workflows
- Test files mirror the source structure
- Use dependency injection to enable mocking

## Development Guidelines

### When Adding New Features
1. Create a new directory under `/Sources/Features/`
2. Implement a coordinator for navigation management
3. Follow the established pattern of separating views, view models, and models
4. Add comprehensive unit tests
5. Update documentation

### When Modifying Architecture
1. Explain the reasoning behind architectural changes
2. Update this CLAUDE.md file with new patterns
3. Ensure changes are consistent across the entire codebase
4. Consider impact on testing and maintainability

### Documentation Standards
- Include `PURPOSE:` sections explaining why code exists
- Document architectural decisions and their benefits
- Provide usage examples for complex APIs
- Explain trade-offs and alternative approaches considered

## Current State (Updated: August 15, 2025)

### ✅ **WORKING FOUNDATION - Ready for Development:**
- **Xcode Project**: Complete working iOS project (TKDojang.xcodeproj)
- **Architecture**: Full MVVM-C implementation with coordinator pattern
- **UI Screens**: Authentication (sign-in/register), Onboarding, Loading, Main Tab structure
- **Navigation**: Coordinator-based navigation with smooth animations
- **GitHub Repository**: Private repo at https://github.com/craigmharris/TKDojang
- **Documentation**: Comprehensive README.md and CLAUDE.md files
- **Development Setup**: Working build configuration, proper .gitignore, git history

### 🧪 **What's Currently Simulated/Placeholder:**
- Authentication service (2-second simulation, no real auth backend)
- Main tab content (placeholder buttons with TODO navigation)
- User data persistence (uses @AppStorage for basic preferences only)
- Technique library, training sessions, progress tracking (not implemented)

### 📁 **Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Working Xcode project
├── TKDojang/Sources/
│   ├── App/                      # App lifecycle and root views
│   │   ├── TKDojangApp.swift     # Main entry point (@main)
│   │   ├── ContentView.swift     # Root navigation container
│   │   └── LoadingView.swift     # Loading screen
│   ├── Core/Coordinators/
│   │   └── AppCoordinator.swift  # Navigation coordinator
│   └── Features/
│       ├── Authentication/       # Sign-in/register UI
│       └── Dashboard/           # Onboarding + main tabs
├── README.md                    # Project overview and architecture
├── CLAUDE.md                    # Development context (this file)
└── Scripts/claude-xcode.sh      # Development helper script
```

## Next Development Session - Pick One Path:

### 🔐 **Path A: Real Authentication System**
**Goal**: Replace simulated login with actual authentication
- Create AuthenticationService protocol and implementation  
- Add secure token storage and session management
- Implement user registration with validation
- Add forgot password and email verification flows
**Impact**: Core user management functionality

### 📚 **Path B: Core Learning Content**  
**Goal**: Build the main Taekwondo learning features
- Design and implement Technique Library with categories
- Create Training Session flows with structured workouts
- Add video/image content management system
- Build progress tracking for completed techniques
**Impact**: Main app value proposition

### 🏗️ **Path C: Technical Infrastructure**
**Goal**: Establish solid technical foundation
- Implement data persistence layer (Core Data or SwiftData)
- Create API service architecture for future backend
- Add comprehensive unit and UI testing framework
- Set up proper error handling and logging
**Impact**: Long-term maintainability and scalability

### 🎨 **Path D: Enhanced User Experience**
**Goal**: Polish the user interface and experience
- Implement user preferences and settings screens
- Add personalization features and user profiles
- Create achievement system with badges and progress
- Enhance UI with better animations and interactions
**Impact**: User engagement and retention

## Development Context Notes:
- **Last Session**: Successfully created working iOS app foundation with complete GitHub setup
- **Architecture Decision**: MVVM-C pattern is working well, continue with this approach
- **Code Quality**: All code includes comprehensive documentation explaining WHY decisions were made
- **Next Session**: Choose one path above and implement 2-3 specific features from that path

## Testing Commands

The project now has a working Xcode configuration:

```bash
# Build the project
# Use Xcode: Cmd+B or Product → Build

# Run unit tests
# Use Xcode: Cmd+U or Product → Test

# Run on simulator
# Use Xcode: Cmd+R or Product → Run

# Build for device
# Select device target and use Cmd+R
```

## Environment Configuration

The app supports multiple environments through build configurations:
- `DEBUG`: Development environment with debug features enabled
- `STAGING`: Staging environment for testing
- `RELEASE`: Production environment

Environment-specific constants are managed in `AppConstants.swift` using compiler directives.

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes