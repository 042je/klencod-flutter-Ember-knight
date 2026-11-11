import 'dart:math' as math;
import 'dart:ui';

/// Pixel art is drawn in code: each sprite is a small character map that is
/// rasterised once into an Image and later drawn with nearest-neighbour
/// scaling, so no image assets are needed.
class _SpriteDef {
  final String id;
  final List<String> rows;
  final Map<String, int> palette;
  const _SpriteDef(this.id, this.rows, this.palette);
}

const List<String> _heroRows = [
  '....hhhh....',
  '...hhhhhh...',
  '...hsssss...',
  '...hsesss...',
  '...hsssss...',
  '....bbbb....',
  '..cbbbbbbc..',
  '.ccbbbbbbcc.',
  '.ssbbbbbbss.',
  '..sbbbbbbs..',
  '...bbbbbb...',
  '...bb..bb...',
  '...bb..bb...',
  '...bb..bb...',
  '..kkk..kkk..',
  '..kkk..kkk..',
];

const List<String> _slimeRows = [
  '............',
  '....gggg....',
  '..gggggggg..',
  '.gggggggggg.',
  '.ggeggggegg.',
  'gggggggggggg',
  'gggggggggggg',
  '.gggggggggg.',
];

const List<String> _batRows = [
  'b..........b',
  'bb...bb...bb',
  'bbb.bbbb.bbb',
  'bbbbbbbbbbbb',
  '.bbbrbbrbbb.',
  '..bbbbbbbb..',
  '...bb..bb...',
  '............',
];

const List<String> _skeletonRows = [
  '...wwww...',
  '..wwwwww..',
  '..wewwew..',
  '..wwwwww..',
  '...wwww...',
  '....ww....',
  '..wwwwww..',
  '.w.wwww.w.',
  '.w.wwww.w.',
  '.w..ww..w.',
  '....ww....',
  '...wwww...',
  '...w..w...',
  '...w..w...',
  '..ww..ww..',
  '..ww..ww..',
];

const List<String> _archerRows = [
  '...gggg...',
  '..gggggg..',
  '.ggeggeg..',
  '..gggggg..',
  '...gggg...',
  '..bbbbbb..',
  '.bbbbbbbbo',
  '.bbbbbbbbo',
  '.g.bbbb.go',
  '.g.bbbb..o',
  '...bbbb...',
  '...bbbb...',
  '...b..b...',
  '...b..b...',
  '..kk..kk..',
  '..kk..kk..',
];

const List<String> _golemRows = [
  '....dddddddd....',
  '...dssssssssd...',
  '..dssseeeesssd..',
  '..dssssssssssd..',
  '...dssssssssd...',
  '.dddssssssssddd.',
  'dsssdssssssdsssd',
  'dsssdssddssdsssd',
  'dsssdssssssdsssd',
  '.ddd.dssssd.ddd.',
  '.....dssssd.....',
  '....dssddssd....',
  '....dss..ssd....',
  '....dss..ssd....',
  '...dddd..dddd...',
  '...dddd..dddd...',
];

const List<_SpriteDef> _defs = [
  _SpriteDef('hero', _heroRows, {
    'h': 0xFF5B3A1E,
    's': 0xFFF2C79B,
    'e': 0xFF222222,
    'b': 0xFF3A6FD8,
    'c': 0xFFC0392B,
    'k': 0xFF3B2A1A,
  }),
  _SpriteDef('slime', _slimeRows, {'g': 0xFF4CAF50, 'e': 0xFF1B1B1B}),
  _SpriteDef('bat', _batRows, {'b': 0xFF6A3FA0, 'r': 0xFFFF4444}),
  _SpriteDef('skeleton', _skeletonRows, {'w': 0xFFE8E8DC, 'e': 0xFF222222}),
  _SpriteDef('archer', _archerRows, {
    'g': 0xFF6DBE45,
    'e': 0xFF111111,
    'b': 0xFF8B5A2B,
    'k': 0xFF3B2A1A,
    'o': 0xFFB07A3A,
  }),
  _SpriteDef('golem', _golemRows, {
    's': 0xFF8A8F98,
    'd': 0xFF565B63,
    'e': 0xFFFFC107,
  }),
  // Bosses reuse the shapes with their own colours and are drawn larger.
  _SpriteDef('slime_king', _slimeRows, {'g': 0xFFE6B800, 'e': 0xFF3E2723}),
  _SpriteDef(
      'bone_lord', _skeletonRows, {'w': 0xFFB388FF, 'e': 0xFFFF1744}),
  _SpriteDef('goblin_chief', _archerRows, {
    'g': 0xFFE53935,
    'e': 0xFF111111,
    'b': 0xFF4E342E,
    'k': 0xFF212121,
    'o': 0xFFFFCA28,
  }),
  _SpriteDef('stone_titan', _golemRows, {
    's': 0xFF6D4C41,
    'd': 0xFF3E2723,
    'e': 0xFFFF5722,
  }),
  _SpriteDef('dragon', _batRows, {'b': 0xFFD32F2F, 'r': 0xFFFFEB3B}),
];

class Sprites {
  static final Map<String, Image> _img = {};

  /// Must be awaited once before the game starts.
  static Future<void> init() async {
    for (final d in _defs) {
      _img[d.id] = await _build(d);
    }
  }

  static Future<Image> _build(_SpriteDef d) {
    var w = 1;
    for (final r in d.rows) {
      w = math.max(w, r.length);
    }
    final h = d.rows.length;
    final rec = PictureRecorder();
    final canvas = Canvas(rec);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < h; y++) {
      final row = d.rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        final c = d.palette[ch];
        if (c == null) continue;
        paint.color = Color(c);
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
    return rec.endRecording().toImage(w, h);
  }

  static Size dims(String id) {
    final i = _img[id];
    if (i == null) return const Size(16, 16);
    return Size(i.width.toDouble(), i.height.toDouble());
  }

  /// Draws sprite [id] with its feet centred on ([footX], [footY]).
  static void draw(
    Canvas c,
    String id,
    double footX,
    double footY,
    int px, {
    bool flip = false,
    bool flash = false,
    double alpha = 1,
  }) {
    final img = _img[id];
    if (img == null) return;
    final w = img.width * px.toDouble();
    final h = img.height * px.toDouble();
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    if (flash) {
      paint.colorFilter = const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop);
    } else if (alpha < 1) {
      final a = (alpha * 255).round().clamp(0, 255).toInt();
      paint.color = Color.fromARGB(a, 255, 255, 255);
    }
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    if (flip) {
      c.save();
      c.translate(footX, 0);
      c.scale(-1, 1);
      c.drawImageRect(img, src, Rect.fromLTWH(-w / 2, footY - h, w, h), paint);
      c.restore();
    } else {
      c.drawImageRect(img, src, Rect.fromLTWH(footX - w / 2, footY - h, w, h), paint);
    }
  }
}
