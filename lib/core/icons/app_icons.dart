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
  
  /// 170+ flat/vector icons (Phosphor Icons style names mapped to Material)
  static const List<IconData> flatIcons = [
    // Category: UI & Actions
    IconData(name: 'house', category: 'navigation'),
    IconData(name: 'magnifying-glass', category: 'navigation'),
    IconData(name: 'bell', category: 'notifications'),
    IconData(name: 'calendar-blank', category: 'time'),
    IconData(name: 'calendar-check', category: 'time'),
    IconData(name: 'clock', category: 'time'),
    IconData(name: 'timer', category: 'time'),
    IconData(name: 'folder', category: 'files'),
    IconData(name: 'file-text', category: 'files'),
    IconData(name: 'archive', category: 'files'),
    IconData(name: 'star', category: 'actions'),
    IconData(name: 'heart', category: 'actions'),
    IconData(name: 'bookmark', category: 'actions'),
    IconData(name: 'tag', category: 'actions'),
    IconData(name: 'flag', category: 'actions'),
    IconData(name: 'check-circle', category: 'actions'),
    IconData(name: 'check-square', category: 'actions'),
    IconData(name: 'plus-circle', category: 'actions'),
    IconData(name: 'minus-circle', category: 'actions'),
    IconData(name: 'x-circle', category: 'actions'),
    IconData(name: 'arrow-right', category: 'arrows'),
    IconData(name: 'arrow-left', category: 'arrows'),
    IconData(name: 'arrow-up', category: 'arrows'),
    IconData(name: 'arrow-down', category: 'arrows'),
    IconData(name: 'caret-right', category: 'arrows'),
    IconData(name: 'caret-left', category: 'arrows'),
    IconData(name: 'caret-up', category: 'arrows'),
    IconData(name: 'caret-down', category: 'arrows'),
    
    // Category: Communication
    IconData(name: 'envelope', category: 'communication'),
    IconData(name: 'chat-circle', category: 'communication'),
    IconData(name: 'phone', category: 'communication'),
    IconData(name: 'video-camera', category: 'communication'),
    IconData(name: 'microphone', category: 'communication'),
    IconData(name: 'link', category: 'communication'),
    IconData(name: 'share', category: 'communication'),
    IconData(name: 'paper-plane', category: 'communication'),
    
    // Category: Media
    IconData(name: 'image', category: 'media'),
    IconData(name: 'camera', category: 'media'),
    IconData(name: 'music-note', category: 'media'),
    IconData(name: 'headphones', category: 'media'),
    IconData(name: 'play', category: 'media'),
    IconData(name: 'pause', category: 'media'),
    IconData(name: 'skip-forward', category: 'media'),
    IconData(name: 'skip-back', category: 'media'),
    
    // Category: Weather
    IconData(name: 'sun', category: 'weather'),
    IconData(name: 'moon', category: 'weather'),
    IconData(name: 'cloud', category: 'weather'),
    IconData(name: 'cloud-rain', category: 'weather'),
    IconData(name: 'cloud-snow', category: 'weather'),
    IconData(name: 'lightning', category: 'weather'),
    IconData(name: 'wind', category: 'weather'),
    IconData(name: 'thermometer', category: 'weather'),
    IconData(name: 'drop', category: 'weather'),
    IconData(name: 'fire', category: 'weather'),
    
    // Category: Food & Drink
    IconData(name: 'coffee', category: 'food'),
    IconData(name: 'wine', category: 'food'),
    IconData(name: 'pizza', category: 'food'),
    IconData(name: 'cake', category: 'food'),
    IconData(name: 'egg', category: 'food'),
    IconData(name: 'plant', category: 'food'),
    IconData(name: 'paw-print', category: 'food'),
    IconData(name: 'fish', category: 'food'),
    
    // Category: Travel & Places
    IconData(name: 'airplane', category: 'travel'),
    IconData(name: 'car', category: 'travel'),
    IconData(name: 'bicycle', category: 'travel'),
    IconData(name: 'train', category: 'travel'),
    IconData(name: 'map-trifold', category: 'travel'),
    IconData(name: 'compass', category: 'travel'),
    IconData(name: 'mountain', category: 'travel'),
    IconData(name: 'palmtree', category: 'travel'),
    IconData(name: 'buildings', category: 'travel'),
    IconData(name: 'house-line', category: 'travel'),
    IconData(name: 'globe', category: 'travel'),
    IconData(name: 'navigation-arrow', category: 'travel'),
    
    // Category: Objects & Things
    IconData(name: 'lightbulb', category: 'objects'),
    IconData(name: 'battery-full', category: 'objects'),
    IconData(name: 'wifi', category: 'objects'),
    IconData(name: 'bluetooth', category: 'objects'),
    IconData(name: 'battery-charging', category: 'objects'),
    IconData(name: 'plug', category: 'objects'),
    IconData(name: 'desktop', category: 'objects'),
    IconData(name: 'laptop', category: 'objects'),
    IconData(name: 'device-mobile', category: 'objects'),
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
    IconData(name: 'umbrella', category: 'objects'),
    IconData(name: 'shopping-bag', category: 'objects'),
    IconData(name: 'shopping-cart', category: 'objects'),
    IconData(name: 'gift', category: 'objects'),
    IconData(name: 't-shirt', category: 'objects'),
    IconData(name: 'crown', category: 'objects'),
    IconData(name: 'diamond', category: 'objects'),
    IconData(name: 'trophy', category: 'objects'),
    IconData(name: 'medal', category: 'objects'),
    IconData(name: 'balloon', category: 'objects'),
    IconData(name: 'confetti', category: 'objects'),
    IconData(name: 'package', category: 'objects'),
    IconData(name: 'wrench', category: 'objects'),
    IconData(name: 'hammer', category: 'objects'),
    IconData(name: 'scissors', category: 'objects'),
    
    // Category: Symbols & Signs
    IconData(name: 'info', category: 'symbols'),
    IconData(name: 'warning', category: 'symbols'),
    IconData(name: 'warning-circle', category: 'symbols'),
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
    IconData(name: 'pen', category: 'symbols'),
    IconData(name: 'pencil', category: 'symbols'),
    IconData(name: 'note-pencil', category: 'symbols'),
    IconData(name: 'notebook', category: 'symbols'),
    IconData(name: 'book', category: 'symbols'),
    IconData(name: 'books', category: 'symbols'),
    IconData(name: 'graduation-cap', category: 'symbols'),
    IconData(name: 'student', category: 'symbols'),
    IconData(name: 'chalkboard', category: 'symbols'),
    IconData(name: 'briefcase', category: 'symbols'),
    IconData(name: 'clipboard', category: 'symbols'),
    IconData(name: 'list-checks', category: 'symbols'),
    IconData(name: 'list-dashes', category: 'symbols'),
    IconData(name: 'list-numbers', category: 'symbols'),
    IconData(name: 'list-bullets', category: 'symbols'),
    IconData(name: 'chart-bar', category: 'symbols'),
    IconData(name: 'chart-line', category: 'symbols'),
    IconData(name: 'chart-pie', category: 'symbols'),
    IconData(name: 'trend-up', category: 'symbols'),
    IconData(name: 'trend-down', category: 'symbols'),
    IconData(name: 'activity', category: 'symbols'),
    IconData(name: 'pulse', category: 'symbols'),
    IconData(name: 'heartbeat', category: 'symbols'),
    IconData(name: 'first-aid', category: 'symbols'),
    IconData(name: 'stethoscope', category: 'symbols'),
    IconData(name: 'pill', category: 'symbols'),
    IconData(name: 'test-tube', category: 'symbols'),
    IconData(name: 'dna', category: 'symbols'),
    IconData(name: 'atom', category: 'symbols'),
    IconData(name: 'flask', category: 'symbols'),
    IconData(name: 'planet', category: 'symbols'),
    IconData(name: 'rocket', category: 'symbols'),
    IconData(name: 'alien', category: 'symbols'),
    IconData(name: 'ghost', category: 'symbols'),
    IconData(name: 'skull', category: 'symbols'),
    IconData(name: 'bat', category: 'symbols'),
    IconData(name: 'spider', category: 'symbols'),
    IconData(name: 'bug', category: 'symbols'),
    IconData(name: 'tree-evergreen', category: 'symbols'),
    IconData(name: 'leaf', category: 'symbols'),
    IconData(name: 'flower', category: 'symbols'),
    IconData(name: 'flower-lotus', category: 'symbols'),
    IconData(name: 'sun-horizon', category: 'symbols'),
    IconData(name: 'rainbow', category: 'symbols'),
    IconData(name: 'star-four-points', category: 'symbols'),
    IconData(name: 'sparkle', category: 'symbols'),
    IconData(name: 'shooting-star', category: 'symbols'),
    IconData(name: 'moon-stars', category: 'symbols'),
    IconData(name: 'eclipse', category: 'symbols'),
    IconData(name: 'galaxy', category: 'symbols'),
    IconData(name: 'telescope', category: 'symbols'),
    IconData(name: 'binoculars', category: 'symbols'),
    IconData(name: 'magnifying-glass-plus', category: 'symbols'),
    IconData(name: 'magnifying-glass-minus', category: 'symbols'),
    IconData(name: 'microscope', category: 'symbols'),
    IconData(name: 'magnet', category: 'symbols'),
    IconData(name: 'battery-warning', category: 'symbols'),
    IconData(name: 'plug-charging', category: 'symbols'),
    IconData(name: 'broadcast', category: 'symbols'),
    IconData(name: 'antenna', category: 'symbols'),
    IconData(name: 'satellite', category: 'symbols'),
    IconData(name: 'radar', category: 'symbols'),
    IconData(name: 'compass', category: 'symbols'),
    IconData(name: 'map-pin', category: 'symbols'),
    IconData(name: 'map-pin-plus', category: 'symbols'),
    IconData(name: 'map-pin-area', category: 'symbols'),
    IconData(name: 'map-trifold', category: 'symbols'),
    IconData(name: 'road-horizon', category: 'symbols'),
    IconData(name: 'bridge', category: 'symbols'),
    IconData(name: 'castle', category: 'symbols'),
    IconData(name: 'church', category: 'symbols'),
    IconData(name: 'mosque', category: 'symbols'),
    IconData(name: 'synagogue', category: 'symbols'),
    IconData(name: 'tent', category: 'symbols'),
    IconData(name: 'warehouse', category: 'symbols'),
    IconData(name: 'hospital', category: 'symbols'),
    IconData(name: 'bank', category: 'symbols'),
    IconData(name: 'factory', category: 'symbols'),
    IconData(name: 'office-building', category: 'symbols'),
    IconData(name: 'storefront', category: 'symbols'),
    IconData(name: 'tent', category: 'symbols'),
    IconData(name: 'tent', category: 'symbols'),
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
