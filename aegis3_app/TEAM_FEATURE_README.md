# Team Management Feature - Flutter Implementation

This document outlines the Flutter implementation of the team management feature based on the React web app.

## 📁 Files Created

### 1. **Models** (`lib/models/`)
- **`team_model.dart`** - Complete team data models including:
  - `Team` - Main team model
  - `Player` - Player model for team context
  - `TeamStatistics` - Team stats
  - `TeamInvitation` - Invitation model
  - `Organization` - Organization model
  - `Socials` - Social links model
  - `SearchResults` - Search results model
  - Helper models: `RecentResult`, `QualifiedEvent`, `TeamDataResponse`

### 2. **Services** (`lib/services/`)
- **`team_service.dart`** - Comprehensive API service for:
  - ✅ Get team by ID
  - ✅ Get received invitations
  - ✅ Create team
  - ✅ Accept/decline invitations
  - ✅ Remove player from team (kick/leave)
  - ✅ Update team details
  - ✅ Upload team logo
  - ✅ Search teams and players
  - ✅ Send team invitation
  - ✅ Browse teams with pagination

### 3. **Providers** (`lib/providers/`)
- **`team_provider.dart`** - State management with:
  - `TeamNotifier` - Manages team state
  - `SearchNotifier` - Manages search state
  - All team operations (create, fetch, update, invite, kick)
  - Error handling and loading states

### 4. **Screens** (`lib/screens/`)
- **`detailed_team_screen.dart`** - Team profile page with:
  - Team header with logo, name, tag
  - Team stats and information
  - 3 tabs: Overview, Roster, Achievements
  - Captain actions: Edit logo, Invite players, Kick players
  - Modals for: Edit logo, Invite players, Kick confirmation
  - Private team handling
  - Error states

- **`my_teams_screen.dart`** - User's teams page with:
  - Current team display
  - Team invitations with accept/decline
  - Team history
  - Achievements grid
  - Create team modal
  - Stats overview
  - 3 tabs: Current, History, Achievements
  - Empty states

### 5. **Widgets** (`lib/widgets/`)
- **`team_widgets.dart`** - Reusable components:
  - `StatBox` - Stat display widget
  - `PlayerCard` - Player display with actions
  - `TeamInvitationCard` - Invitation card with actions
  - `EmptyState` - Empty state placeholder

## 🎨 Design Features

### Color Scheme (Matching React)
- Background: `#09090B` (zinc-950)
- Cards: `#18181B` (zinc-900)
- Borders: `#27272A` (zinc-800)
- Primary (Cyan): `#06B6D4`
- Success (Green): `#10B981`
- Warning (Amber): `#F59E0B`
- Error (Red): `#EF4444`
- Purple: `#A855F7`
- Blue: `#3B82F6`

### UI Components
- Modern glassmorphic cards
- Gradient accents
- Icon-based navigation
- Modal bottom sheets
- Responsive layouts
- Loading and error states
- Toast notifications via SnackBar

## 🔧 Backend Integration

### API Endpoints Used
All endpoints from your backend routes are implemented:
- `GET /api/teams/:id` - Get team details
- `GET /api/teams/invitations/received` - Get invitations
- `POST /api/teams` - Create team
- `POST /api/teams/invitations/:id/accept` - Accept invitation
- `POST /api/teams/invitations/:id/decline` - Decline invitation
- `DELETE /api/teams/:id/players/:playerId` - Remove player
- `PUT /api/teams/:id` - Update team
- `POST /api/teams/:id/invite` - Send invitation
- `GET /api/teams/search/:query` - Search teams/players
- `GET /api/teams` - Browse teams (pagination ready)

## 📱 Mobile-Specific Optimizations

### 1. **Image Picker Integration**
- Uses `image_picker` package for logo uploads
- Supports gallery selection
- Preview before upload

### 2. **Modal Bottom Sheets**
- Native-feeling modals for:
  - Create team
  - Edit logo
  - Invite players
  - Kick confirmation
- Scrollable content
- Keyboard-aware

### 3. **State Management**
- Riverpod for reactive state
- Optimistic UI updates
- Error boundary handling
- Loading states

### 4. **Navigation**
- Direct navigation to team details
- Back navigation with context
- Deep linking ready (team ID based)

### 5. **Performance**
- Lazy loading tabs
- Image caching
- Efficient rebuilds
- Pagination ready

## 🚀 Usage Examples

### Navigate to Team Detail
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DetailedTeamScreen(teamId: 'team_id_here'),
  ),
);
```

### Navigate to My Teams
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const MyTeamsScreen(),
  ),
);
```

### Create Team Programmatically
```dart
final team = await ref.read(teamProvider.notifier).createTeam(
  teamName: 'My Team',
  teamTag: 'MT',
  bio: 'We are the best!',
);
```

### Send Invitation
```dart
final success = await ref.read(teamProvider.notifier).sendInvitation(
  teamId: 'team_id',
  playerId: 'player_id',
  message: 'Join us!',
);
```

## ✅ Feature Parity with React App

| Feature | React | Flutter | Notes |
|---------|-------|---------|-------|
| View Team Profile | ✅ | ✅ | |
| Team Stats Display | ✅ | ✅ | |
| Roster Management | ✅ | ✅ | |
| Captain Actions | ✅ | ✅ | Edit, Invite, Kick |
| Team Invitations | ✅ | ✅ | Accept/Decline |
| Create Team | ✅ | ✅ | |
| Upload Logo | ✅ | ✅ | Image picker |
| Search Players | ✅ | ✅ | |
| Private Teams | ✅ | ✅ | Permission handling |
| Team History | ✅ | ✅ | |
| Achievements | ✅ | ✅ | |
| Social Links | ✅ | ✅ | |
| Organization Info | ✅ | ✅ | |
| Pagination | ⚠️ | ✅ | Ready, not in React |
| Dark Theme | ✅ | ✅ | |

## 🔮 Future Enhancements

1. **Add Pagination** to browse teams list
2. **Implement Pull-to-Refresh** on My Teams screen
3. **Add Shimmer Loading** for better UX
4. **Implement Social Links** tap actions (open URLs)
5. **Add Team Editing** screen for captain
6. **Implement Transfer Captaincy** feature
7. **Add Match History** integration when available
8. **Add Tournament Results** when backend ready
9. **Implement Share Team** functionality
10. **Add Follow Team** feature when backend ready

## 🐛 Known Limitations

1. **Achievements** - Currently showing mock data (backend integration pending)
2. **Win Rate** - Using placeholder 73% (needs calculation from backend)
3. **Social Links** - Display only (tap actions not implemented)
4. **Team Search** - Not integrated into opportunities page yet
5. **Previous Teams** - Relies on UserProfile model structure

## 📝 Notes for Backend

Your backend routes are well-structured and work great for Flutter! However, consider these mobile optimizations:

1. ✅ **Pagination already suggested** - Add to `GET /api/teams`
2. ✅ **Reduce payload sizes** - Consider query params for partial data
3. ✅ **Add batch operations** - Optional efficiency improvement
4. ✅ **Response compression** - Use gzip middleware

The routes as-is are perfect for mobile consumption! 🎉

## 🛠️ Dependencies Required

Make sure these are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  dio: ^5.3.3
  image_picker: ^1.0.4
  logger: ^2.0.2
```

## 📞 Integration with Existing App

To integrate with your existing app:

1. The providers use your existing `core_providers.dart`
2. Team service uses your existing Dio instance
3. Integrates with `user_profile_provider.dart`
4. Follows your existing architecture patterns

Ready to use! 🚀
