# TKDojang

A comprehensive iOS application for learning and practicing Taekwondo, designed to guide users from beginner to advanced levels with structured lessons, technique demonstrations, and progress tracking.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Design Patterns](#design-patterns)
- [Getting Started](#getting-started)
- [Development Guidelines](#development-guidelines)
- [Feature Roadmap](#feature-roadmap)

## Architecture Overview

This app follows a **clean, scalable architecture** designed for long-term maintainability and team collaboration:

### Core Architectural Decisions

1. **MVVM-C (Model-View-ViewModel-Coordinator)**: Separates concerns and makes navigation testable
2. **Feature-based organization**: Groups related functionality together instead of separating by file type
3. **Protocol-oriented programming**: Enables dependency injection and easy testing
4. **Reactive programming with Combine**: Provides responsive UI and data flow
5. **SwiftUI + UIKit hybrid**: Modern SwiftUI for UI with UIKit when needed

### Why These Choices?

- **Scalability**: Structure supports adding new features without creating chaos
- **Testability**: Dependency injection and separation of concerns enable comprehensive testing
- **Team collaboration**: Clear boundaries make it easier for multiple developers to work together
- **Maintainability**: Well-documented, single-responsibility components are easier to modify
- **Performance**: Reactive patterns minimize unnecessary UI updates

## Project Structure

```
TKDojang/
├── Sources/
│   ├── App/                           # App lifecycle and root views
│   │   ├── TKDojangApp.swift               # Main app entry point
│   │   ├── ContentView.swift               # Root navigation container
│   │   └── LoadingView.swift               # App loading state
│   │
│   ├── Features/                      # Feature modules (business logic)
│   │   ├── Authentication/            # User login/registration
│   │   │   └── AuthenticationCoordinatorView.swift
│   │   ├── Dashboard/                 # Main user interface
│   │   │   ├── OnboardingCoordinatorView.swift
│   │   │   └── MainTabCoordinatorView.swift
│   │   ├── Techniques/               # Technique library and details
│   │   ├── Training/                 # Training sessions and workouts
│   │   ├── Progress/                 # Progress tracking and analytics
│   │   └── Profile/                  # User profile and settings
│   │
│   ├── Core/                         # Shared utilities and services
│   │   ├── Networking/               # API clients and authentication
│   │   │   └── AuthenticationService.swift
│   │   ├── Database/                 # Data persistence layer
│   │   ├── Extensions/               # Swift/UIKit extensions
│   │   ├── Utils/                    # Helper utilities and models
│   │   │   ├── Models.swift          # Core data models
│   │   │   └── UserPreferencesService.swift
│   │   └── Coordinators/             # Navigation coordinators
│   │       └── AppCoordinator.swift  # Main app navigation
│   │
│   └── Resources/                    # App assets and localizations
│       ├── Assets/                   # Images, icons, colors
│       ├── Localizations/            # Multi-language support
│       ├── Fonts/                    # Custom typography
│       └── Sounds/                   # Audio files
│
├── Tests/                            # Test suites
│   ├── UnitTests/                    # Business logic tests
│   ├── UITests/                      # User interface tests
│   └── TestHelpers/                  # Testing utilities
│
├── Documentation/                    # Project documentation
└── Scripts/                          # Build and deployment scripts
```

### Key Directory Explanations

#### `/Sources/App/`
Contains the application's entry point and root-level views. These files manage the overall app lifecycle and coordinate between major application flows.

#### `/Sources/Features/`
Each subdirectory represents a major feature area of the app. This organization:
- **Reduces merge conflicts** - developers can work on different features independently
- **Improves code discoverability** - all related files are grouped together
- **Enables feature flags** - entire features can be easily enabled/disabled
- **Supports modularization** - features can potentially become separate modules

#### `/Sources/Core/`
Shared code that multiple features depend on:
- **Networking**: API clients, authentication services, network utilities
- **Database**: Data persistence, Core Data models, caching strategies
- **Extensions**: Swift/UIKit extensions used throughout the app
- **Utils**: Helper functions, constants, shared business logic
- **Coordinators**: Navigation coordinators that manage app flow

#### `/Tests/`
Comprehensive testing strategy:
- **UnitTests**: Fast, isolated tests for business logic and utilities
- **UITests**: End-to-end tests for user workflows
- **TestHelpers**: Shared testing utilities, mocks, and test data

## Design Patterns

### 1. Coordinator Pattern

**Purpose**: Separates navigation logic from view controllers

```swift
// Example: AppCoordinator manages app-wide navigation
class AppCoordinator: ObservableObject {
    @Published var currentFlow: AppFlow = .loading
    
    func showMainFlow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .main
        }
    }
}
```

**Benefits**:
- Navigation logic is testable
- Views remain focused on display logic
- Easy to modify navigation flows
- Supports deep linking and programmatic navigation

### 2. Repository Pattern

**Purpose**: Abstracts data access and provides a consistent interface

```swift
// Example: AuthenticationService protocol
protocol AuthenticationServiceProtocol {
    var isAuthenticated: CurrentValueSubject<Bool, Never> { get }
    func login(email: String, password: String) -> AnyPublisher<User, AuthenticationError>
}
```

**Benefits**:
- Enables easy testing with mock implementations
- Separates business logic from data access details
- Supports multiple data sources (API, database, cache)
- Makes it easy to change backend services

### 3. Reactive Programming with Combine

**Purpose**: Creates responsive UI that automatically updates when data changes

```swift
// Example: Reactive authentication state
authenticationService.isAuthenticated
    .receive(on: DispatchQueue.main)
    .sink { [weak self] isAuthenticated in
        self?.handleAuthenticationStateChange(isAuthenticated)
    }
    .store(in: &cancellables)
```

**Benefits**:
- Eliminates manual state synchronization
- Reduces bugs from outdated UI state
- Enables complex data flow with simple composition
- Provides built-in error handling and threading

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0 deployment target
- Swift 5.9 or later

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone [repository-url]
   cd TKDojang
   ```

2. **Open in Xcode**:
   ```bash
   open TKDojang.xcodeproj
   ```

3. **Build and run**:
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

### Configuration

The app uses several configuration files that you may need to customize:

- **Environment Configuration**: TODO - Add environment-specific settings
- **API Endpoints**: TODO - Configure backend service URLs
- **Feature Flags**: TODO - Enable/disable experimental features

## Development Guidelines

### Code Style

1. **Documentation**: Every public interface must include comprehensive documentation
   - Explain **WHY** decisions were made, not just what the code does
   - Include usage examples for complex APIs
   - Document architectural patterns and their benefits

2. **Naming Conventions**:
   - Use descriptive, self-documenting names
   - Prefer clarity over brevity
   - Follow Swift API Design Guidelines

3. **File Organization**:
   - Group related functionality together
   - Use feature-based organization
   - Keep files focused on single responsibilities

### Testing Strategy

1. **Unit Tests**: Test business logic, utilities, and data transformations
2. **Integration Tests**: Test service interactions and data flow
3. **UI Tests**: Test critical user workflows and accessibility
4. **Performance Tests**: Monitor app launch time and memory usage

### Adding New Features

1. **Create feature directory** under `/Sources/Features/`
2. **Implement coordinator** for feature navigation
3. **Add models** to appropriate Core directory
4. **Write comprehensive tests** for new functionality
5. **Update documentation** including this README

## Feature Roadmap

### Phase 1: Foundation (Current)
- [x] App architecture and navigation
- [x] User authentication system
- [x] Basic UI structure
- [ ] User onboarding flow
- [ ] Profile management

### Phase 2: Core Learning Features
- [ ] Technique library with video demonstrations
- [ ] Structured training sessions
- [ ] Forms (Poomsae) practice with guidance
- [ ] Progress tracking and analytics

### Phase 3: Enhanced Experience
- [ ] Personalized learning paths
- [ ] Achievement system and badges
- [ ] Social features and community
- [ ] Offline content synchronization

### Phase 4: Advanced Features
- [ ] AI-powered technique analysis
- [ ] Virtual reality training experiences
- [ ] Integration with wearable devices
- [ ] Competition and tournament features

## Contributing

1. Follow the established architecture patterns
2. Write comprehensive tests for new features
3. Update documentation for any architectural changes
4. Ensure all code includes detailed documentation
5. Test on multiple device sizes and orientations

## Architecture Benefits

This architecture provides several key advantages:

### For Developers
- **Clear separation of concerns** makes code easier to understand and modify
- **Dependency injection** enables comprehensive testing and flexible implementations
- **Feature-based organization** reduces merge conflicts and improves collaboration
- **Comprehensive documentation** accelerates onboarding and knowledge transfer

### For Users
- **Responsive UI** through reactive programming patterns
- **Consistent experience** through centralized navigation and state management
- **Reliable functionality** through comprehensive testing strategy
- **Smooth performance** through efficient data flow and caching

### For Business
- **Faster feature development** through reusable components and clear patterns
- **Easier maintenance** through well-documented, single-responsibility components
- **Better quality** through testable architecture and comprehensive test coverage
- **Future flexibility** through modular design and protocol-oriented interfaces

This architecture serves as a solid foundation for building a world-class Taekwondo learning application that can grow and evolve with user needs while maintaining high code quality and developer productivity.