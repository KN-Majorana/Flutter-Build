/// RGB の3色を保持する不変モデル。
///
/// ColorRGBクラスの扱い方
/// Ex) final color = ColorRGB(255, 128, 0);
///     print(color.r); // 255
///     print(color.g); // 128
///     print(color.b); // 0
class ColorRGB {
  final int r;
  final int g;
  final int b;

  const ColorRGB(this.r, this.g, this.b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorRGB && r == other.r && g == other.g && b == other.b;

  @override
  int get hashCode => Object.hash(r, g, b);
}
