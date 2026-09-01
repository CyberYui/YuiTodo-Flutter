/// Built-in avatar icons (28 icons)
/// Source: /Users/yui/Pictures/avatars/ (center-cropped, 512x512)
class AppIcons {
  AppIcons._();

  static const List<String> names = [
    'aimisi', 'anke', 'bachi', 'buouxiong', 'changli', 'chun',
    'dengdeng', 'feibi', 'huimu', 'jinxi', 'katixiya', 'kelaita',
    'lamiya', 'lilisi', 'luokeke', 'luxiya', 'misaiya', 'moning',
    'qianxiao', 'qishi', 'qu', 'taoqi', 'wanhua', 'woman',
    'yalisha', 'yangyang', 'zhezhi', 'zhixia',
  ];

  static String pathFor(String name) => 'assets/icons/$name.png';

  static List<String> get all => names;
}
