# Walkthrough - KizzuAncien Audit & Implementation

I have performed a comprehensive audit and implemented critical fixes and new features for KizzuAncien. Below is a summary of the accomplishments.

## 1. Authentication & Session Persistence (Critical)
- **Fix**: Implemented a request queue in `ApiService` to handle concurrent 401 errors. This prevents multiple simultaneous refresh requests and ensures that all pending requests retry with the new token, fixing unexpected logouts.
- **Improved Security**: Added better error handling and session cleanup in `AuthProvider`.

## 2. Challenge Details & Workflow
- **UI Overhaul**: Redesigned `ChallengeDetailScreen` with better typography, spacing, and hierarchy.
- **Cover Images**: Added support for challenge cover images in both backend (Mongoose) and frontend (Flutter).
- **Visibility Fix**: Challenges now remain visible to recipients after submission, showing as "Reviewing" on the Home and Profile screens.
- **Data Immortality**: Ensured that submission data (images, text) is correctly fetched and rendered after challenge completion.

## 3. Discussion Section (New Feature)
- **Real-time Chat**: Added a discussion section to every challenge where participants can chat.
- **Code Support**: Implemented basic markdown-style code block support (triple backticks) with a fixed-width font display for C++, HTML, etc.
- **Backend**: Created a new `Message` model, controller, and routes.

## 4. Notification System Refactor
- **Capped Storage**: Implemented logic to store only the last 50 notifications per user. The backend now automatically deletes the oldest notification when the limit is reached using a new `createCappedNotification` utility.
- **FCM-Only Reminders**: Moved daily reminders, streak reminders, and challenge alerts to a direct scheduler-to-FCM flow. These are no longer stored in the database, reducing clutter.
- **Database Focus**: Only core events (Friend Request, Accepted, Challenge status changes) are now persisted.

## 5. Friend Request System (State Machine)
- **Unified State**: Introduced `relationshipStatus` in the backend as the single source of truth for UI rendering (`NOT_FRIENDS`, `PENDING_SENT`, `PENDING_RECEIVED`, `FRIENDS`).
- **Immediate Feedback**: The friend profile UI now updates instantly when a request is sent, showing "Request Sent" and disabling further clicks.
- **Robust UI**: Returning to a profile now correctly fetches and displays the existing relationship state, fixing the "Add Friend" repeat bug.

## 6. Challenge Filters (New Feature)
- **Organization**: Added a category filter dropdown to the **Home Screen**, **Profile Screen**, and **Friend Profile Screen**.
- **Options**: Users can now filter by "All", "Received", or "Sent" challenges.

## 5. Streak System & Logic
- **Timezone Leniency**: Updated the server-side streak logic to include a 48-hour leniency window, accounting for timezone shifts and edge cases near midnight.
- **Longest Streak**: Verified that `longestStreak` is correctly updated on both `Friend` and `User` models.

## 6. Android Native Splash Screen
- **Branding**: Updated `launch_background.xml` to use the app logo on a black background.
- **Android 12+ Support**: Implemented the Android 12+ Splash API using `Theme.SplashScreen` in `values-v31/styles.xml`.

## 7. Security & Code Quality
- **Authorization**: Added ownership checks to `getSubmissionByChallenge` to ensure only participants can view private submissions.
- **Null Safety**: Cleaned up null safety warnings and improved error handling in `ChallengeProvider` and `AuthProvider`.

## Verification Summary
- **Code Analysis**: Verified syntax and structure for all modified Flutter files.
- **Logic Audit**: Manually audited the new authentication interceptor and streak leniency logic.
- **Backend Sync**: Ensured all frontend model changes (Message, coverImage) have corresponding backend support.

### Files Modified
- [api_service.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/services/api_service.dart)
- [challenge_details_screen.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/screens/challenge_details_screen.dart)
- [challenge_provider.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/providers/challenge_provider.dart)
- [home_screen.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/screens/home_screen.dart)
- [profile_screen.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/screens/profile_screen.dart)
- [friend_profile_screen.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/screens/friend_profile_screen.dart)
- [challenge.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/models/challenge.dart)
- [message.dart](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/lib/models/message.dart)
- [challengeController.js](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/server/src/controllers/challengeController.js)
- [challengeRoutes.js](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/server/src/routes/challengeRoutes.js)
- [Message.js](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/server/src/models/Message.js)
- [messageController.js](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/server/src/controllers/messageController.js)
- [launch_background.xml](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/android/app/src/main/res/drawable/launch_background.xml)
- [styles.xml](file:///C:/Users/vkart/Music/WORK/apps_rough/KizzuAncien/android/app/src/main/res/values-v31/styles.xml)
