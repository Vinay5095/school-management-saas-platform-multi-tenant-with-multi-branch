# SPEC-049: Typography System
## Comprehensive Typography Configuration for Multi-Tenant School Management SaaS

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 5 hours  
> **Dependencies**: SPEC-046 (Theme), SPEC-047 (Design Tokens)

---

## 📋 OVERVIEW

### Purpose
Establish a robust, scalable typography system that:
- Provides consistent text styles across the platform
- Ensures readability and accessibility
- Supports responsive font sizing
- Includes font loading optimization
- Works seamlessly with Tailwind CSS

### Key Features
- ✅ Type scale system (12px to 96px)
- ✅ Font weight system (300 to 900)
- ✅ Line height tokens
- ✅ Letter spacing utilities
- ✅ Responsive typography
- ✅ Font family configuration
- ✅ Text utilities and components

---

## 🎯 TYPOGRAPHY ARCHITECTURE

### 1. Font Family Configuration

```typescript
// src/config/typography/fonts.ts
import { Inter, Poppins, JetBrains_Mono } from 'next/font/google';

/**
 * Primary font for UI and body text
 * Excellent readability, supports many languages
 */
export const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
  weight: ['300', '400', '500', '600', '700', '800', '900'],
});

/**
 * Display font for headings and important text
 * More distinctive, better for headlines
 */
export const poppins = Poppins({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-poppins',
  weight: ['300', '400', '500', '600', '700', '800', '900'],
});

/**
 * Monospace font for code and data
 * Perfect for IDs, codes, technical content
 */
export const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-mono',
  weight: ['300', '400', '500', '600', '700', '800'],
});

// Font family tokens
export const fontFamily = {
  sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
  display: ['var(--font-poppins)', 'system-ui', 'sans-serif'],
  mono: ['var(--font-mono)', 'Courier New', 'monospace'],
} as const;

export type FontFamily = keyof typeof fontFamily;
```

### 2. Type Scale System

```typescript
// src/config/typography/scale.ts

/**
 * Font size scale following a consistent ratio
 * Base size: 16px (1rem)
 * Scale ratio: 1.25 (Major Third)
 */
export const fontSize = {
  // Display sizes (for heroes, landing pages)
  '6xl': ['3.75rem', { lineHeight: '1', letterSpacing: '-0.025em' }],  // 60px
  '5xl': ['3rem', { lineHeight: '1', letterSpacing: '-0.025em' }],      // 48px
  '4xl': ['2.25rem', { lineHeight: '1.1', letterSpacing: '-0.02em' }],  // 36px
  
  // Heading sizes
  '3xl': ['1.875rem', { lineHeight: '1.2', letterSpacing: '-0.01em' }], // 30px
  '2xl': ['1.5rem', { lineHeight: '1.3', letterSpacing: '-0.01em' }],   // 24px
  'xl': ['1.25rem', { lineHeight: '1.4', letterSpacing: '0' }],         // 20px
  'lg': ['1.125rem', { lineHeight: '1.5', letterSpacing: '0' }],        // 18px
  
  // Body sizes
  'base': ['1rem', { lineHeight: '1.5', letterSpacing: '0' }],          // 16px
  'sm': ['0.875rem', { lineHeight: '1.5', letterSpacing: '0' }],        // 14px
  'xs': ['0.75rem', { lineHeight: '1.5', letterSpacing: '0.01em' }],    // 12px
  'xxs': ['0.625rem', { lineHeight: '1.5', letterSpacing: '0.01em' }],  // 10px
} as const;

export type FontSize = keyof typeof fontSize;
```

### 3. Font Weight System

```typescript
// src/config/typography/weights.ts

export const fontWeight = {
  light: '300',
  normal: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
  extrabold: '800',
  black: '900',
} as const;

export type FontWeight = keyof typeof fontWeight;

// Semantic weight tokens
export const semanticWeights = {
  body: fontWeight.normal,      // 400
  emphasis: fontWeight.medium,  // 500
  strong: fontWeight.semibold,  // 600
  heading: fontWeight.bold,     // 700
  display: fontWeight.extrabold, // 800
} as const;
```

### 4. Line Height System

```typescript
// src/config/typography/lineHeight.ts

export const lineHeight = {
  none: '1',
  tight: '1.25',
  snug: '1.375',
  normal: '1.5',
  relaxed: '1.625',
  loose: '2',
} as const;

export type LineHeight = keyof typeof lineHeight;

// Contextual line heights
export const contextualLineHeight = {
  display: lineHeight.none,     // 1
  heading: lineHeight.tight,    // 1.25
  body: lineHeight.normal,      // 1.5
  caption: lineHeight.relaxed,  // 1.625
} as const;
```

### 5. Letter Spacing System

```typescript
// src/config/typography/letterSpacing.ts

export const letterSpacing = {
  tighter: '-0.05em',
  tight: '-0.025em',
  normal: '0',
  wide: '0.025em',
  wider: '0.05em',
  widest: '0.1em',
} as const;

export type LetterSpacing = keyof typeof letterSpacing;

// Contextual letter spacing
export const contextualLetterSpacing = {
  display: letterSpacing.tight,   // -0.025em
  heading: letterSpacing.tight,   // -0.025em
  body: letterSpacing.normal,     // 0
  caption: letterSpacing.wide,    // 0.025em
  label: letterSpacing.wider,     // 0.05em
} as const;
```

---

## 🛠️ IMPLEMENTATION

### Complete Typography Configuration

```typescript
// src/config/typography/index.ts
import { fontFamily, FontFamily } from './fonts';
import { fontSize, FontSize } from './scale';
import { fontWeight, FontWeight, semanticWeights } from './weights';
import { lineHeight, LineHeight, contextualLineHeight } from './lineHeight';
import { letterSpacing, LetterSpacing, contextualLetterSpacing } from './letterSpacing';

export const typography = {
  fontFamily,
  fontSize,
  fontWeight,
  lineHeight,
  letterSpacing,
  semanticWeights,
  contextualLineHeight,
  contextualLetterSpacing,
} as const;

// Text style presets
export const textStyles = {
  // Display styles
  displayLarge: {
    fontSize: fontSize['6xl'],
    fontWeight: semanticWeights.display,
    lineHeight: contextualLineHeight.display,
    letterSpacing: contextualLetterSpacing.display,
    fontFamily: fontFamily.display,
  },
  displayMedium: {
    fontSize: fontSize['5xl'],
    fontWeight: semanticWeights.display,
    lineHeight: contextualLineHeight.display,
    letterSpacing: contextualLetterSpacing.display,
    fontFamily: fontFamily.display,
  },
  displaySmall: {
    fontSize: fontSize['4xl'],
    fontWeight: semanticWeights.display,
    lineHeight: contextualLineHeight.display,
    letterSpacing: contextualLetterSpacing.display,
    fontFamily: fontFamily.display,
  },

  // Heading styles
  h1: {
    fontSize: fontSize['3xl'],
    fontWeight: semanticWeights.heading,
    lineHeight: contextualLineHeight.heading,
    letterSpacing: contextualLetterSpacing.heading,
    fontFamily: fontFamily.display,
  },
  h2: {
    fontSize: fontSize['2xl'],
    fontWeight: semanticWeights.heading,
    lineHeight: contextualLineHeight.heading,
    letterSpacing: contextualLetterSpacing.heading,
    fontFamily: fontFamily.display,
  },
  h3: {
    fontSize: fontSize.xl,
    fontWeight: semanticWeights.heading,
    lineHeight: contextualLineHeight.heading,
    letterSpacing: contextualLetterSpacing.heading,
    fontFamily: fontFamily.display,
  },
  h4: {
    fontSize: fontSize.lg,
    fontWeight: semanticWeights.strong,
    lineHeight: contextualLineHeight.heading,
    letterSpacing: contextualLetterSpacing.heading,
    fontFamily: fontFamily.sans,
  },

  // Body styles
  bodyLarge: {
    fontSize: fontSize.lg,
    fontWeight: semanticWeights.body,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.body,
    fontFamily: fontFamily.sans,
  },
  bodyMedium: {
    fontSize: fontSize.base,
    fontWeight: semanticWeights.body,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.body,
    fontFamily: fontFamily.sans,
  },
  bodySmall: {
    fontSize: fontSize.sm,
    fontWeight: semanticWeights.body,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.body,
    fontFamily: fontFamily.sans,
  },

  // Label styles
  labelLarge: {
    fontSize: fontSize.base,
    fontWeight: semanticWeights.emphasis,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.label,
    fontFamily: fontFamily.sans,
  },
  labelMedium: {
    fontSize: fontSize.sm,
    fontWeight: semanticWeights.emphasis,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.label,
    fontFamily: fontFamily.sans,
  },
  labelSmall: {
    fontSize: fontSize.xs,
    fontWeight: semanticWeights.emphasis,
    lineHeight: contextualLineHeight.body,
    letterSpacing: contextualLetterSpacing.label,
    fontFamily: fontFamily.sans,
  },

  // Caption styles
  caption: {
    fontSize: fontSize.xs,
    fontWeight: semanticWeights.body,
    lineHeight: contextualLineHeight.caption,
    letterSpacing: contextualLetterSpacing.caption,
    fontFamily: fontFamily.sans,
  },

  // Code/Monospace style
  code: {
    fontSize: fontSize.sm,
    fontWeight: semanticWeights.body,
    lineHeight: contextualLineHeight.body,
    letterSpacing: letterSpacing.normal,
    fontFamily: fontFamily.mono,
  },
} as const;

export type TextStyle = keyof typeof textStyles;

// Export all typography types
export type {
  FontFamily,
  FontSize,
  FontWeight,
  LineHeight,
  LetterSpacing,
};

export * from './fonts';
export * from './scale';
export * from './weights';
export * from './lineHeight';
export * from './letterSpacing';
```

### Tailwind CSS Integration

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';
import { typography } from './src/config/typography';

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: typography.fontFamily,
      fontSize: typography.fontSize,
      fontWeight: typography.fontWeight,
      lineHeight: typography.lineHeight,
      letterSpacing: typography.letterSpacing,
    },
  },
  plugins: [],
};

export default config;
```

### Font Loading in Layout

```typescript
// src/app/layout.tsx
import { inter, poppins, jetbrainsMono } from '@/config/typography/fonts';
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${poppins.variable} ${jetbrainsMono.variable}`}
    >
      <body className="font-sans antialiased">
        {children}
      </body>
    </html>
  );
}
```

---

## 📦 REACT COMPONENTS

### Text Component

```typescript
// src/components/typography/Text.tsx
import React from 'react';
import { cn } from '@/lib/utils';
import { type TextStyle } from '@/config/typography';

interface TextProps extends React.HTMLAttributes<HTMLElement> {
  as?: 'p' | 'span' | 'div' | 'label' | 'legend';
  variant?: TextStyle;
  className?: string;
  children: React.ReactNode;
}

const variantStyles: Record<TextStyle, string> = {
  displayLarge: 'text-6xl font-extrabold leading-none tracking-tight font-display',
  displayMedium: 'text-5xl font-extrabold leading-none tracking-tight font-display',
  displaySmall: 'text-4xl font-extrabold leading-tight tracking-tight font-display',
  h1: 'text-3xl font-bold leading-tight tracking-tight font-display',
  h2: 'text-2xl font-bold leading-tight tracking-tight font-display',
  h3: 'text-xl font-bold leading-snug tracking-tight font-display',
  h4: 'text-lg font-semibold leading-snug tracking-tight',
  bodyLarge: 'text-lg font-normal leading-normal',
  bodyMedium: 'text-base font-normal leading-normal',
  bodySmall: 'text-sm font-normal leading-normal',
  labelLarge: 'text-base font-medium leading-normal tracking-wide',
  labelMedium: 'text-sm font-medium leading-normal tracking-wide',
  labelSmall: 'text-xs font-medium leading-normal tracking-wide',
  caption: 'text-xs font-normal leading-relaxed tracking-wide',
  code: 'text-sm font-normal leading-normal font-mono',
};

export function Text({
  as: Component = 'p',
  variant = 'bodyMedium',
  className,
  children,
  ...props
}: TextProps) {
  return (
    <Component
      className={cn(variantStyles[variant], className)}
      {...props}
    >
      {children}
    </Component>
  );
}
```

### Heading Component

```typescript
// src/components/typography/Heading.tsx
import React from 'react';
import { cn } from '@/lib/utils';

interface HeadingProps extends React.HTMLAttributes<HTMLHeadingElement> {
  as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
  size?: '6xl' | '5xl' | '4xl' | '3xl' | '2xl' | 'xl' | 'lg';
  className?: string;
  children: React.ReactNode;
}

const sizeStyles = {
  '6xl': 'text-6xl font-extrabold leading-none tracking-tight',
  '5xl': 'text-5xl font-extrabold leading-none tracking-tight',
  '4xl': 'text-4xl font-extrabold leading-tight tracking-tight',
  '3xl': 'text-3xl font-bold leading-tight tracking-tight',
  '2xl': 'text-2xl font-bold leading-tight tracking-tight',
  'xl': 'text-xl font-bold leading-snug tracking-tight',
  'lg': 'text-lg font-semibold leading-snug tracking-tight',
};

export function Heading({
  as: Component = 'h2',
  size = '2xl',
  className,
  children,
  ...props
}: HeadingProps) {
  return (
    <Component
      className={cn('font-display', sizeStyles[size], className)}
      {...props}
    >
      {children}
    </Component>
  );
}
```

### Code Component

```typescript
// src/components/typography/Code.tsx
import React from 'react';
import { cn } from '@/lib/utils';

interface CodeProps extends React.HTMLAttributes<HTMLElement> {
  inline?: boolean;
  className?: string;
  children: React.ReactNode;
}

export function Code({ inline = false, className, children, ...props }: CodeProps) {
  if (inline) {
    return (
      <code
        className={cn(
          'font-mono text-sm px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800',
          'text-gray-900 dark:text-gray-100',
          className
        )}
        {...props}
      >
        {children}
      </code>
    );
  }

  return (
    <pre
      className={cn(
        'font-mono text-sm p-4 rounded-lg overflow-x-auto',
        'bg-gray-100 dark:bg-gray-800',
        'text-gray-900 dark:text-gray-100',
        className
      )}
    >
      <code {...props}>{children}</code>
    </pre>
  );
}
```

---

## 🎯 TYPOGRAPHY UTILITIES

### Responsive Typography

```typescript
// src/lib/typography/responsive.ts

/**
 * Generate responsive font size classes
 */
export function responsiveText(
  mobile: string,
  tablet?: string,
  desktop?: string
): string {
  const classes = [mobile];
  
  if (tablet) classes.push(`md:${tablet}`);
  if (desktop) classes.push(`lg:${desktop}`);
  
  return classes.join(' ');
}

// Usage example:
// <h1 className={responsiveText('text-2xl', 'text-3xl', 'text-4xl')}>
//   Responsive Heading
// </h1>
```

### Text Truncation

```typescript
// src/lib/typography/truncate.ts

export const truncateStyles = {
  single: 'truncate',
  multi: (lines: number) => `line-clamp-${lines}`,
  ellipsis: 'overflow-hidden text-ellipsis whitespace-nowrap',
} as const;
```

---

## ✅ TESTING

### Typography Tests

```typescript
// src/config/typography/__tests__/typography.test.ts
import { describe, it, expect } from '@jest/globals';
import { typography, textStyles } from '../index';

describe('Typography System', () => {
  describe('Font Families', () => {
    it('exports all font families', () => {
      expect(typography.fontFamily.sans).toBeDefined();
      expect(typography.fontFamily.display).toBeDefined();
      expect(typography.fontFamily.mono).toBeDefined();
    });
  });

  describe('Font Sizes', () => {
    it('exports all font sizes', () => {
      expect(typography.fontSize.base).toBeDefined();
      expect(typography.fontSize.lg).toBeDefined();
      expect(typography.fontSize['3xl']).toBeDefined();
    });

    it('includes line height and letter spacing', () => {
      const [size, styles] = typography.fontSize.base;
      expect(size).toBe('1rem');
      expect(styles.lineHeight).toBeDefined();
      expect(styles.letterSpacing).toBeDefined();
    });
  });

  describe('Text Styles', () => {
    it('exports all text style presets', () => {
      expect(textStyles.h1).toBeDefined();
      expect(textStyles.bodyMedium).toBeDefined();
      expect(textStyles.caption).toBeDefined();
    });

    it('includes all required properties', () => {
      const style = textStyles.h1;
      expect(style.fontSize).toBeDefined();
      expect(style.fontWeight).toBeDefined();
      expect(style.lineHeight).toBeDefined();
      expect(style.letterSpacing).toBeDefined();
      expect(style.fontFamily).toBeDefined();
    });
  });
});
```

### Component Tests

```typescript
// src/components/typography/__tests__/Text.test.tsx
import { render, screen } from '@testing-library/react';
import { Text } from '../Text';

describe('Text Component', () => {
  it('renders with default props', () => {
    render(<Text>Hello World</Text>);
    expect(screen.getByText('Hello World')).toBeInTheDocument();
  });

  it('renders with variant prop', () => {
    render(<Text variant="h1">Heading</Text>);
    const element = screen.getByText('Heading');
    expect(element.className).toContain('text-3xl');
  });

  it('renders as different HTML elements', () => {
    const { container } = render(<Text as="span">Span text</Text>);
    expect(container.querySelector('span')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    render(<Text className="custom-class">Text</Text>);
    expect(screen.getByText('Text').className).toContain('custom-class');
  });
});
```

---

## 📚 USAGE EXAMPLES

### Basic Typography

```typescript
// Using text variants
<Text variant="h1">Main Heading</Text>
<Text variant="bodyMedium">Body text content</Text>
<Text variant="caption">Caption text</Text>

// Using heading component
<Heading as="h1" size="3xl">Page Title</Heading>

// Using code component
<Code inline>const x = 10;</Code>
<Code>{`
function hello() {
  console.log('Hello!');
}
`}</Code>
```

### Responsive Typography

```typescript
<h1 className="text-2xl md:text-3xl lg:text-4xl font-bold">
  Responsive Heading
</h1>

<p className="text-sm md:text-base lg:text-lg">
  Responsive paragraph text
</p>
```

### Academic Content

```typescript
// Student name
<Text variant="h3" className="font-display">John Doe</Text>

// Grade display
<Text variant="displayMedium" className="text-primary-600">
  A+
</Text>

// Roll number (monospace)
<Code inline>STU-2024-001</Code>

// Subject title
<Heading as="h2" size="xl">Mathematics</Heading>
```

---

## ♿ ACCESSIBILITY

### Accessibility Features
- ✅ Minimum font size of 14px for body text
- ✅ Sufficient line height for readability (1.5 for body)
- ✅ Proper heading hierarchy (h1-h6)
- ✅ High contrast text colors
- ✅ Scalable font sizes (rem-based)
- ✅ Support for browser zoom

### Best Practices
```typescript
// Use semantic HTML
<h1>Main Page Title</h1>  // Not <div className="text-3xl">

// Maintain heading hierarchy
<h1>Title</h1>
<h2>Subtitle</h2>
<h3>Section</h3>

// Use appropriate line height
<p className="leading-normal">Body text with comfortable line spacing</p>
```

---

## 📖 DOCUMENTATION

### Typography Guidelines

1. **Headings**: Use display font (Poppins) for visual hierarchy
2. **Body Text**: Use sans font (Inter) for optimal readability
3. **Code/Data**: Use mono font (JetBrains Mono) for technical content
4. **Responsive**: Scale typography based on viewport size
5. **Consistency**: Use text style presets for consistency

### Best Practices

✅ **DO**:
- Use the Text component for consistent styling
- Scale font sizes responsively
- Maintain proper heading hierarchy
- Use appropriate line heights
- Test with different font sizes (accessibility)

❌ **DON'T**:
- Use arbitrary font sizes
- Skip heading levels
- Use inline styles for typography
- Set line heights too tight
- Rely solely on font weight for emphasis

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install Google Fonts (Inter, Poppins, JetBrains Mono)
- [ ] Create typography configuration files
- [ ] Set up Tailwind CSS integration
- [ ] Configure font loading in layout
- [ ] Create Text component
- [ ] Create Heading component
- [ ] Create Code component
- [ ] Implement typography utilities
- [ ] Write comprehensive tests
- [ ] Create Storybook stories
- [ ] Document usage examples
- [ ] Test accessibility
- [ ] Verify responsive behavior

---

## 📝 NOTES

- Fonts are loaded from Google Fonts with `display: swap` for performance
- All font sizes use rem units for accessibility
- Typography system supports dark mode automatically
- Text components are fully typed for TypeScript safety
- Responsive typography scales from mobile to desktop

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
