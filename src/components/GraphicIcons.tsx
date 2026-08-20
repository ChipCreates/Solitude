import React from "react";

interface IconProps {
  size?: number;
  className?: string;
  style?: React.CSSProperties;
}

const renderImageIcon = (
  srcWebp: string,
  srcPng: string,
  alt: string,
  size: number,
  widthMultiplier: number = 1.0,
  className?: string,
  style?: React.CSSProperties
) => {
  const height = size;
  const width = Math.round(size * widthMultiplier);
  return (
    <picture className="inline-flex items-center justify-center pointer-events-none select-none">
      <source srcSet={srcWebp} type="image/webp" />
      <img
        src={srcPng}
        alt={alt}
        width={width}
        height={height}
        className={className}
        style={{
          height: height,
          width: width,
          maxWidth: "none",
          objectFit: "contain",
          filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.5))",
          ...style,
        }}
      />
    </picture>
  );
};

/**
 * Solitude Theme - New Game (+) Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicPlusIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/add.webp", "/assets/icons/add.png", "New Game", size, 1.0, className, style);

/**
 * Solitude Theme - Solver Key Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicKeyIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/solver.webp", "/assets/icons/solver.png", "Solver", size, 0.9, className, style);

/**
 * Solitude Theme - Hint Lightbulb Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicHintIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/hint.webp", "/assets/icons/hint.png", "Hint", size, 0.75, className, style);

/**
 * Solitude Theme - Undo Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicUndoIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/undo.webp", "/assets/icons/undo.png", "Undo", size, 0.95, className, style);

/**
 * Solitude Theme - Emporium Store Icon
 * Widened container to present the full canopy width of the store asset
 */
export const GraphicStoreIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/emporium.webp", "/assets/icons/emporium.png", "Emporium", size, 1.35, className, style);

/**
 * Solitude Theme - Trophies Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicTrophyIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/trophies.webp", "/assets/icons/trophies.png", "Trophies", size, 1.0, className, style);

/**
 * Solitude Theme - Settings Icon
 * Gold & Charcoal Beveled Gear
 */
export const GraphicSettingsIcon: React.FC<IconProps> = ({ size = 26, className, style }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 48 48"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
    style={{ overflow: "visible", filter: "drop-shadow(0 3px 6px rgba(0,0,0,0.6))", ...style }}
  >
    <defs>
      <linearGradient id="solGearGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#fff5bd" />
        <stop offset="50%" stopColor="#e9c349" />
        <stop offset="100%" stopColor="#7a5c0d" />
      </linearGradient>
    </defs>
    <circle cx="24" cy="24" r="15" fill="url(#solGearGold)" stroke="#fff6c4" strokeWidth="0.8" />
    <path
      d="M24 4V8M24 40V44M4 24H8M40 24H44M9.8 9.8L12.7 12.5M35.3 35.3L38.1 38.1M9.8 38.1L12.7 35.3M35.3 12.5L38.1 9.8"
      stroke="url(#solGearGold)"
      strokeWidth="4"
      strokeLinecap="round"
    />
    <circle cx="24" cy="24" r="7" fill="#0d1b13" stroke="#e9c349" strokeWidth="1.2" />
  </svg>
);

/**
 * Solitude Theme - Home Icon
 * Vibrant Solid Yellow / Gold House
 */
export const GraphicHomeIcon: React.FC<IconProps> = ({ size = 26, className, style }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 48 48"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
    style={{ overflow: "visible", filter: "drop-shadow(0 3px 6px rgba(0,0,0,0.7))", ...style }}
  >
    <defs>
      <linearGradient id="solHomeSolidYellow" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#fff8b5" />
        <stop offset="50%" stopColor="#f5ce42" />
        <stop offset="100%" stopColor="#e9c349" />
      </linearGradient>
    </defs>
    {/* Shadow Background Fill */}
    <path
      d="M24 5L5 21H10V42H38V21H43L24 5Z"
      fill="#000000"
      opacity="0.5"
      transform="translate(0, 2)"
    />
    {/* Solid Yellow House Body & Roof */}
    <path
      d="M24 5L5 21H11V41C11 41.6 11.4 42 12 42H36C36.6 42 37 41.6 37 41V21H43L24 5Z"
      fill="url(#solHomeSolidYellow)"
      stroke="#fffec7"
      strokeWidth="1.2"
    />
    {/* Dark Door Inset for Contrast */}
    <path
      d="M20 42V30C20 27.8 21.8 26 24 26C26.2 26 28 27.8 28 30V42H20Z"
      fill="#111111"
      stroke="#fff5bd"
      strokeWidth="1"
    />
    {/* Golden Knob */}
    <circle cx="26" cy="35" r="1.2" fill="#f5ce42" />
  </svg>
);

/**
 * Solitude Theme - Power Up Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicPowerUpIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/power-up.webp", "/assets/icons/power-up.png", "Power-ups", size, 1.0, className, style);
export const GraphicZapIcon = GraphicPowerUpIcon;

/**
 * Solitude Theme - Help Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicHelpIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/help.webp", "/assets/icons/help.png", "Help", size, 1.0, className, style);

/**
 * Solitude Theme - About Icon
 * High-DPI WebP/PNG Graphic Asset
 */
export const GraphicAboutIcon: React.FC<IconProps> = ({ size = 26, className, style }) =>
  renderImageIcon("/assets/icons/about.webp", "/assets/icons/about.png", "About", size, 1.0, className, style);

/**
 * Solitude Theme - User / Profile Icon
 * 3D Beveled Gold Shield with User Silhouette
 */
export const GraphicUserIcon: React.FC<IconProps> = ({ size = 26, className, style }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 48 48"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
    style={{ overflow: "visible", filter: "drop-shadow(0 3px 6px rgba(0,0,0,0.6))", ...style }}
  >
    <defs>
      <linearGradient id="solUserGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#fff8b5" />
        <stop offset="50%" stopColor="#e9c349" />
        <stop offset="100%" stopColor="#8a670f" />
      </linearGradient>
    </defs>
    <circle cx="24" cy="24" r="20" fill="url(#solUserGold)" stroke="#fffec7" strokeWidth="1" />
    <circle cx="24" cy="24" r="15" fill="#0d1b13" stroke="#e9c349" strokeWidth="1" />
    <circle cx="24" cy="18" r="5" fill="url(#solUserGold)" />
    <path
      d="M14 34C14 28.5 18.5 25 24 25C29.5 25 34 28.5 34 34"
      fill="url(#solUserGold)"
    />
  </svg>
);



