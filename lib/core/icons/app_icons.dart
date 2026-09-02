/// Icon data class
class IconData {
  final String name;
  final String? assetPath;
  final String? codePoint;
  final String category;
  
  const IconData({
    required this.name,
    this.assetPath,
    this.codePoint,
    this.category = 'general',
  });
  
  String get displayLabel => name;
}

/// All app icons (200+)
class AppIcons {
  AppIcons._();
  
  /// 28 built-in avatar icons (PNG assets)
  static const List<String> avatarNames = [
    'aimisi', 'anke', 'bachi', 'buouxiong', 'changli', 'chun',
    'dengdeng', 'feibi', 'huimu', 'jinxi', 'katixiya', 'kelaita',
    'lamiya', 'lilisi', 'luokeke', 'luxiya', 'misaiya', 'moning',
    'qianxiao', 'qishi', 'qu', 'taoqi', 'wanhua', 'woman',
    'yalisha', 'yangyang', 'zhezhi', 'zhixia',
  ];
  
  /// 200+ flat/vector icons (Phosphor Icons style names mapped to Material)
  static const List<IconData> flatIcons = [
    // Category: Navigation (20 icons)
    IconData(name: 'house', category: 'navigation'),
    IconData(name: 'magnifying-glass', category: 'navigation'),
    IconData(name: 'map-trifold', category: 'navigation'),
    IconData(name: 'compass', category: 'navigation'),
    IconData(name: 'navigation-arrow', category: 'navigation'),
    IconData(name: 'map-pin', category: 'navigation'),
    IconData(name: 'globe', category: 'navigation'),
    IconData(name: 'arrow-right', category: 'navigation'),
    IconData(name: 'arrow-left', category: 'navigation'),
    IconData(name: 'arrow-up', category: 'navigation'),
    IconData(name: 'arrow-down', category: 'navigation'),
    IconData(name: 'caret-right', category: 'navigation'),
    IconData(name: 'caret-left', category: 'navigation'),
    IconData(name: 'caret-up', category: 'navigation'),
    IconData(name: 'caret-down', category: 'navigation'),
    IconData(name: 'signpost', category: 'navigation'),
    IconData(name: 'path', category: 'navigation'),
    IconData(name: 'crosshair', category: 'navigation'),
    IconData(name: 'crosshair-simple', category: 'navigation'),
    IconData(name: 'target', category: 'navigation'),
    
    // Category: Notifications (15 icons)
    IconData(name: 'bell', category: 'notifications'),
    IconData(name: 'bell-ringing', category: 'notifications'),
    IconData(name: 'bell-slash', category: 'notifications'),
    IconData(name: 'bell-z', category: 'notifications'),
    IconData(name: 'notification-badge', category: 'notifications'),
    IconData(name: 'chat-circle', category: 'notifications'),
    IconData(name: 'chat-circle-dots', category: 'notifications'),
    IconData(name: 'chat-circle-text', category: 'notifications'),
    IconData(name: 'chat-teardrop', category: 'notifications'),
    IconData(name: 'chat-teardrop-dots', category: 'notifications'),
    IconData(name: 'chat-teardrop-text', category: 'notifications'),
    IconData(name: 'envelope', category: 'notifications'),
    IconData(name: 'envelope-open', category: 'notifications'),
    IconData(name: 'envelope-simple', category: 'notifications'),
    IconData(name: 'envelope-simple-open', category: 'notifications'),
    
    // Category: Time (15 icons)
    IconData(name: 'calendar-blank', category: 'time'),
    IconData(name: 'calendar-check', category: 'time'),
    IconData(name: 'calendar-plus', category: 'time'),
    IconData(name: 'calendar-x', category: 'time'),
    IconData(name: 'clock', category: 'time'),
    IconData(name: 'clock-afternoon', category: 'time'),
    IconData(name: 'clock-clockwise', category: 'time'),
    IconData(name: 'clock-countdown', category: 'time'),
    IconData(name: 'timer', category: 'time'),
    IconData(name: 'hourglass', category: 'time'),
    IconData(name: 'hourglass-high', category: 'time'),
    IconData(name: 'hourglass-low', category: 'time'),
    IconData(name: 'hourglass-medium', category: 'time'),
    IconData(name: 'watch', category: 'time'),
    IconData(name: 'stopwatch', category: 'time'),
    
    // Category: Files (15 icons)
    IconData(name: 'folder', category: 'files'),
    IconData(name: 'folder-open', category: 'files'),
    IconData(name: 'folder-plus', category: 'files'),
    IconData(name: 'folder-minus', category: 'files'),
    IconData(name: 'folder-simple', category: 'files'),
    IconData(name: 'folder-simple-plus', category: 'files'),
    IconData(name: 'folder-simple-minus', category: 'files'),
    IconData(name: 'folder-simple-star', category: 'files'),
    IconData(name: 'folder-star', category: 'files'),
    IconData(name: 'file-text', category: 'files'),
    IconData(name: 'file', category: 'files'),
    IconData(name: 'file-plus', category: 'files'),
    IconData(name: 'file-minus', category: 'files'),
    IconData(name: 'file-pdf', category: 'files'),
    IconData(name: 'file-doc', category: 'files'),
    
    // Category: Actions (20 icons)
    IconData(name: 'star', category: 'actions'),
    IconData(name: 'star-half', category: 'actions'),
    IconData(name: 'heart', category: 'actions'),
    IconData(name: 'heart-straight', category: 'actions'),
    IconData(name: 'heart-straight-break', category: 'actions'),
    IconData(name: 'heart-break', category: 'actions'),
    IconData(name: 'bookmark', category: 'actions'),
    IconData(name: 'bookmark-simple', category: 'actions'),
    IconData(name: 'tag', category: 'actions'),
    IconData(name: 'tags', category: 'actions'),
    IconData(name: 'flag', category: 'actions'),
    IconData(name: 'flag-banner', category: 'actions'),
    IconData(name: 'check-circle', category: 'actions'),
    IconData(name: 'check-square', category: 'actions'),
    IconData(name: 'check', category: 'actions'),
    IconData(name: 'plus-circle', category: 'actions'),
    IconData(name: 'minus-circle', category: 'actions'),
    IconData(name: 'x-circle', category: 'actions'),
    IconData(name: 'plus', category: 'actions'),
    IconData(name: 'minus', category: 'actions'),
    
    // Category: Arrows (15 icons)
    IconData(name: 'arrow-right', category: 'arrows'),
    IconData(name: 'arrow-left', category: 'arrows'),
    IconData(name: 'arrow-up', category: 'arrows'),
    IconData(name: 'arrow-down', category: 'arrows'),
    IconData(name: 'arrow-up-right', category: 'arrows'),
    IconData(name: 'arrow-up-left', category: 'arrows'),
    IconData(name: 'arrow-down-right', category: 'arrows'),
    IconData(name: 'arrow-down-left', category: 'arrows'),
    IconData(name: 'arrow-bend-up-right', category: 'arrows'),
    IconData(name: 'arrow-bend-up-left', category: 'arrows'),
    IconData(name: 'arrow-bend-down-right', category: 'arrows'),
    IconData(name: 'arrow-bend-down-left', category: 'arrows'),
    IconData(name: 'arrow-square-up-right', category: 'arrows'),
    IconData(name: 'arrow-square-up-left', category: 'arrows'),
    IconData(name: 'arrow-square-down-right', category: 'arrows'),
    
    // Category: Communication (15 icons)
    IconData(name: 'envelope', category: 'communication'),
    IconData(name: 'chat-circle', category: 'communication'),
    IconData(name: 'phone', category: 'communication'),
    IconData(name: 'phone-call', category: 'communication'),
    IconData(name: 'phone-disconnect', category: 'communication'),
    IconData(name: 'phone-incoming', category: 'communication'),
    IconData(name: 'phone-outgoing', category: 'communication'),
    IconData(name: 'phone-slash', category: 'communication'),
    IconData(name: 'video-camera', category: 'communication'),
    IconData(name: 'video-camera-slash', category: 'communication'),
    IconData(name: 'microphone', category: 'communication'),
    IconData(name: 'microphone-slash', category: 'communication'),
    IconData(name: 'link', category: 'communication'),
    IconData(name: 'link-break', category: 'communication'),
    IconData(name: 'share', category: 'communication'),
    
    // Category: Media (15 icons)
    IconData(name: 'image', category: 'media'),
    IconData(name: 'image-square', category: 'media'),
    IconData(name: 'images', category: 'media'),
    IconData(name: 'images-square', category: 'media'),
    IconData(name: 'camera', category: 'media'),
    IconData(name: 'camera-rotate', category: 'media'),
    IconData(name: 'camera-slash', category: 'media'),
    IconData(name: 'music-note', category: 'media'),
    IconData(name: 'music-note-simple', category: 'media'),
    IconData(name: 'music-notes', category: 'media'),
    IconData(name: 'music-notes-plus', category: 'media'),
    IconData(name: 'music-notes-simple', category: 'media'),
    IconData(name: 'headphones', category: 'media'),
    IconData(name: 'speaker', category: 'media'),
    IconData(name: 'speaker-simple-none', category: 'media'),
    
    // Category: Weather (15 icons)
    IconData(name: 'sun', category: 'weather'),
    IconData(name: 'sun-dim', category: 'weather'),
    IconData(name: 'sun-horizon', category: 'weather'),
    IconData(name: 'moon', category: 'weather'),
    IconData(name: 'moon-stars', category: 'weather'),
    IconData(name: 'cloud', category: 'weather'),
    IconData(name: 'cloud-rain', category: 'weather'),
    IconData(name: 'cloud-snow', category: 'weather'),
    IconData(name: 'cloud-fog', category: 'weather'),
    IconData(name: 'cloud-sun', category: 'weather'),
    IconData(name: 'cloud-moon', category: 'weather'),
    IconData(name: 'lightning', category: 'weather'),
    IconData(name: 'wind', category: 'weather'),
    IconData(name: 'thermometer', category: 'weather'),
    IconData(name: 'drop', category: 'weather'),
    
    // Category: Food & Drink (15 icons)
    IconData(name: 'coffee', category: 'food'),
    IconData(name: 'wine', category: 'food'),
    IconData(name: 'pizza', category: 'food'),
    IconData(name: 'cake', category: 'food'),
    IconData(name: 'egg', category: 'food'),
    IconData(name: 'plant', category: 'food'),
    IconData(name: 'paw-print', category: 'food'),
    IconData(name: 'fish', category: 'food'),
    IconData(name: 'fish-simple', category: 'food'),
    IconData(name: 'hamburger', category: 'food'),
    IconData(name: 'french-fries', category: 'food'),
    IconData(name: 'ice-cream', category: 'food'),
    IconData(name: 'cooking-pot', category: 'food'),
    IconData(name: 'knife', category: 'food'),
    IconData(name: 'fork', category: 'food'),
    
    // Category: Travel & Places (20 icons)
    IconData(name: 'airplane', category: 'travel'),
    IconData(name: 'airplane-tilt', category: 'travel'),
    IconData(name: 'airplane-in-flight', category: 'travel'),
    IconData(name: 'airplane-landing', category: 'travel'),
    IconData(name: 'airplane-takeoff', category: 'travel'),
    IconData(name: 'car', category: 'travel'),
    IconData(name: 'car-simple', category: 'travel'),
    IconData(name: 'bicycle', category: 'travel'),
    IconData(name: 'train', category: 'travel'),
    IconData(name: 'train-simple', category: 'travel'),
    IconData(name: 'bus', category: 'travel'),
    IconData(name: 'motorcycle', category: 'travel'),
    IconData(name: 'sailboat', category: 'travel'),
    IconData(name: 'boat', category: 'travel'),
    IconData(name: 'map-trifold', category: 'travel'),
    IconData(name: 'mountain', category: 'travel'),
    IconData(name: 'palmtree', category: 'travel'),
    IconData(name: 'buildings', category: 'travel'),
    IconData(name: 'house-line', category: 'travel'),
    IconData(name: 'globe', category: 'travel'),
    
    // Category: Objects & Things (20 icons)
    IconData(name: 'lightbulb', category: 'objects'),
    IconData(name: 'battery-full', category: 'objects'),
    IconData(name: 'battery-charging', category: 'objects'),
    IconData(name: 'battery-warning', category: 'objects'),
    IconData(name: 'plug', category: 'objects'),
    IconData(name: 'desktop', category: 'objects'),
    IconData(name: 'laptop', category: 'objects'),
    IconData(name: 'device-mobile', category: 'objects'),
    IconData(name: 'device-mobile-camera', category: 'objects'),
    IconData(name: 'device-mobile-speaker', category: 'objects'),
    IconData(name: 'watch', category: 'objects'),
    IconData(name: 'printer', category: 'objects'),
    IconData(name: 'keyboard', category: 'objects'),
    IconData(name: 'mouse', category: 'objects'),
    IconData(name: 'headset', category: 'objects'),
    IconData(name: 'speaker', category: 'objects'),
    IconData(name: 'lock', category: 'objects'),
    IconData(name: 'lock-open', category: 'objects'),
    IconData(name: 'key', category: 'objects'),
    IconData(name: 'shield', category: 'objects'),
    
    // Category: Symbols & Signs (30 icons)
    IconData(name: 'info', category: 'symbols'),
    IconData(name: 'warning', category: 'symbols'),
    IconData(name: 'warning-circle', category: 'symbols'),
    IconData(name: 'warning-octagon', category: 'symbols'),
    IconData(name: 'question', category: 'symbols'),
    IconData(name: 'equals', category: 'symbols'),
    IconData(name: 'percent', category: 'symbols'),
    IconData(name: 'infinity', category: 'symbols'),
    IconData(name: 'peace', category: 'symbols'),
    IconData(name: 'yin-yang', category: 'symbols'),
    IconData(name: 'smiley', category: 'symbols'),
    IconData(name: 'smiley-wink', category: 'symbols'),
    IconData(name: 'smiley-meh', category: 'symbols'),
    IconData(name: 'smiley-sad', category: 'symbols'),
    IconData(name: 'smiley-nervous', category: 'symbols'),
    IconData(name: 'smiley-blank', category: 'symbols'),
    IconData(name: 'thumbs-up', category: 'symbols'),
    IconData(name: 'thumbs-down', category: 'symbols'),
    IconData(name: 'hand-pointing', category: 'symbols'),
    IconData(name: 'hand-wave', category: 'symbols'),
    IconData(name: 'handshake', category: 'symbols'),
    IconData(name: 'hands-clapping', category: 'symbols'),
    IconData(name: 'eye', category: 'symbols'),
    IconData(name: 'eye-slash', category: 'symbols'),
    IconData(name: 'brain', category: 'symbols'),
    IconData(name: 'target', category: 'symbols'),
    IconData(name: 'ruler', category: 'symbols'),
    IconData(name: 'paint-brush', category: 'symbols'),
    IconData(name: 'paint-bucket', category: 'symbols'),
    IconData(name: 'palette', category: 'symbols'),
  ];
  
  /// Get all icon names (avatar + flat)
  static List<String> get all => [...avatarNames, ...flatIcons.map((i) => i.name)];
  
  /// Get avatar icon path
  static String avatarPath(String name) => 'assets/icons/$name.png';
  
  /// Get flat icon data
  static IconData? flatIcon(String name) {
    try {
      return flatIcons.firstWhere((i) => i.name == name);
    } catch (_) {
      return null;
    }
  }
  
  /// Check if icon is avatar (PNG asset)
  static bool isAvatar(String name) => avatarNames.contains(name);
  
  /// Get icon by name (returns path or null for flat icons)
  static String? pathFor(String name) {
    if (isAvatar(name)) return avatarPath(name);
    return null;
  }
}
