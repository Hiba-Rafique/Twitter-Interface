# Firebase Twitter Interface

A Twitter-like social media interface built with Flutter and Firebase, featuring posts, likes, comments, and sharing functionality.

## Features

- **Post Creation**: Create text posts with multiple image support
- **Image Upload**: Upload images to Cloudflare R2 storage via API
- **Likes**: Like/unlike posts and comments with real-time updates
- **Comments**: Add comments to posts with like functionality
- **Share**: Share posts (placeholder for now)
- **Responsive Design**: Works on both mobile and web platforms
- **Real-time Updates**: Uses Firebase Firestore for real-time data synchronization

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── post_model.dart         # Post, Like, and Comment models
├── services/
│   ├── post_service.dart       # Firebase operations for posts
│   └── storage_service.dart    # Cloudflare R2 storage service
└── pages/
    └── twitter_interface_page.dart  # Main Twitter-like interface
```

## Setup

1. **Dependencies**: Make sure you have all required dependencies in `pubspec.yaml`
2. **Firebase**: Configure Firebase for your project
3. **Storage Service**: The app uses a Node.js backend API for Cloudflare R2 storage

## Usage

### Basic Usage

```dart
// Navigate to the Twitter interface
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TwitterInterfacePage(
      userId: 'current-user-id',
      companyId: 'company-id',
    ),
  ),
);
```

### Post Service

```dart
// Create a post
await PostService.instance.createPost(
  userId: 'user-id',
  companyId: 'company-id',
  content: 'This is my post!',
  imageUrls: ['image-url-1', 'image-url-2'],
);

// Toggle like
await PostService.instance.toggleLike(
  postId: 'post-id',
  userId: 'user-id',
);

// Add comment
await PostService.instance.addComment(
  postId: 'post-id',
  userId: 'user-id',
  content: 'Great post!',
);
```

### Storage Service

```dart
// Initialize storage service
StorageService.instance.setCompanyId('company-id');

// Upload image
final result = await StorageService.instance.uploadFile(
  imageBytes,
  'filename.jpg',
  folder: 'posts',
  contentType: 'image/jpeg',
);
```

## Features Details

### Post Features
- Text content with multiple image support
- Real-time like counts
- Comment threads
- Share counts
- Timestamp display with timeago formatting

### Interaction Features
- **Like**: Tap to like/unlike posts and comments
- **Long Press**: Hold like button to see who liked
- **Comments**: Tap comment icon to view/add comments
- **Share**: Tap share icon (placeholder functionality)

### UI Features
- Dark theme matching Twitter's aesthetic
- Responsive grid layout for multiple images
- Smooth animations and transitions
- Loading states and error handling

## Firebase Collections

### Posts Collection Structure
```json
{
  "userId": "string",
  "companyId": "string", 
  "content": "string",
  "imageUrls": ["string"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "likes": [
    {
      "userId": "string",
      "createdAt": "timestamp"
    }
  ],
  "comments": [
    {
      "id": "string",
      "userId": "string",
      "content": "string",
      "createdAt": "timestamp",
      "updatedAt": "timestamp",
      "likes": [
        {
          "userId": "string", 
          "createdAt": "timestamp"
        }
      ],
      "isDeleted": "boolean"
    }
  ],
  "shareCount": "number",
  "isDeleted": "boolean"
}
```

## Dependencies

- `flutter`: Flutter framework
- `cloud_firestore`: Firebase Firestore database
- `firebase_core`: Firebase core functionality
- `image_picker`: Image selection from gallery
- `http`: HTTP requests for storage API
- `cached_network_image`: Cached network images
- `timeago`: Time formatting
- `flutter_staggered_grid_view`: Grid layouts
- `provider`: State management

## Notes

- The app uses a custom Node.js backend for Cloudflare R2 storage
- User authentication should be integrated before production use
- Error handling can be enhanced based on specific requirements
- The share functionality is currently a placeholder and can be extended

## Future Enhancements

- User profiles and avatars
- Post editing and deletion
- Threaded conversations
- Media previews and thumbnails
- Push notifications
- Advanced search and filtering
- Analytics and insights
