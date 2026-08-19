const imageCache = new Map<string, HTMLImageElement>();

// Lazily loads and caches a board/felt texture image for repeated canvas
// draws inside the render loop. Returns null until the image has actually
// finished loading — callers should fall back to the plain gradient fill
// in that case (and on any subsequent frame once it resolves).
export function getCachedImage(url: string): HTMLImageElement | null {
  let img = imageCache.get(url);
  if (!img) {
    img = new Image();
    img.src = url;
    imageCache.set(url, img);
  }
  return img.complete && img.naturalWidth > 0 ? img : null;
}
