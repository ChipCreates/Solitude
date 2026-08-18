export class OverlayValidator {
  public static relativeLuminance(r: number, g: number, b: number): number {
    const rsRGB = r / 255;
    const gsRGB = g / 255;
    const bsRGB = b / 255;

    const rL = rsRGB <= 0.03928 ? rsRGB / 12.92 : Math.pow((rsRGB + 0.055) / 1.055, 2.4);
    const gL = gsRGB <= 0.03928 ? gsRGB / 12.92 : Math.pow((gsRGB + 0.055) / 1.055, 2.4);
    const bL = bsRGB <= 0.03928 ? bsRGB / 12.92 : Math.pow((bsRGB + 0.055) / 1.055, 2.4);

    return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL;
  }

  public static calculateContrast(rgb1: [number, number, number], rgb2: [number, number, number]): number {
    const l1 = this.relativeLuminance(rgb1[0], rgb1[1], rgb1[2]);
    const l2 = this.relativeLuminance(rgb2[0], rgb2[1], rgb2[2]);

    const lighter = Math.max(l1, l2);
    const darker = Math.min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  public static isLegible(overlayRgb: [number, number, number], intensity: number): boolean {
    if (intensity < 0.1) return true;

    const blend = (base: number, overlay: number) =>
      Math.round(base * (1 - intensity) + overlay * intensity);

    const blendedRed: [number, number, number] = [
      blend(204, overlayRgb[0]),
      blend(51, overlayRgb[1]),
      blend(51, overlayRgb[2]),
    ];

    const blendedBlack: [number, number, number] = [
      blend(0, overlayRgb[0]),
      blend(0, overlayRgb[1]),
      blend(0, overlayRgb[2]),
    ];

    const blendedWhite: [number, number, number] = [
      blend(255, overlayRgb[0]),
      blend(255, overlayRgb[1]),
      blend(255, overlayRgb[2]),
    ];

    const redVsWhite = this.calculateContrast(blendedRed, blendedWhite);
    const blackVsWhite = this.calculateContrast(blendedBlack, blendedWhite);
    const redVsBlack = this.calculateContrast(blendedRed, blendedBlack);

    return redVsWhite >= 3.0 && blackVsWhite >= 3.0 && redVsBlack >= 2.0;
  }
}
