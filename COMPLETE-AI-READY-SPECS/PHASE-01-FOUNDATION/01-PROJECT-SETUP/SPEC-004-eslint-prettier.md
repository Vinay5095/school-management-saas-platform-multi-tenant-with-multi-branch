# SPEC-004: ESLint + Prettier Configuration

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-004  
**Title**: ESLint + Prettier Code Quality Configuration  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: ✅ COMPLETE  
**Estimated Time**: 20 minutes  

---

## 📋 DESCRIPTION

Configure ESLint and Prettier for consistent code quality, formatting, and best practices enforcement across the entire School Management SaaS project. This includes TypeScript support, React hooks rules, accessibility checks, and automated formatting.

## 🎯 SUCCESS CRITERIA

- [ ] ESLint configured with comprehensive rule sets
- [ ] Prettier integrated for consistent code formatting
- [ ] TypeScript and React rules enabled
- [ ] Accessibility (a11y) checks configured
- [ ] Import sorting and organization rules
- [ ] Pre-commit hooks for quality enforcement
- [ ] IDE integration fully functional
- [ ] Zero linting errors on clean codebase

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. ESLint Configuration

**File**: `.eslintrc.json`
```json
{
  "extends": [
    "next/core-web-vitals",
    "@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-type-checked",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "plugin:jsx-a11y/recommended",
    "plugin:import/recommended",
    "plugin:import/typescript",
    "prettier"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "project": ["./tsconfig.json"],
    "tsconfigRootDir": "."
  },
  "plugins": [
    "@typescript-eslint",
    "react",
    "react-hooks",
    "jsx-a11y",
    "import",
    "unused-imports"
  ],
  "rules": {
    // TypeScript specific rules
    "@typescript-eslint/no-unused-vars": "off",
    "unused-imports/no-unused-imports": "error",
    "unused-imports/no-unused-vars": [
      "warn",
      {
        "vars": "all",
        "varsIgnorePattern": "^_",
        "args": "after-used",
        "argsIgnorePattern": "^_"
      }
    ],
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-unsafe-assignment": "warn",
    "@typescript-eslint/no-unsafe-member-access": "warn",
    "@typescript-eslint/no-unsafe-call": "warn",
    "@typescript-eslint/no-unsafe-return": "warn",
    "@typescript-eslint/consistent-type-imports": [
      "error",
      {
        "prefer": "type-imports",
        "disallowTypeAnnotations": false
      }
    ],
    "@typescript-eslint/consistent-type-definitions": ["error", "interface"],
    "@typescript-eslint/prefer-nullish-coalescing": "error",
    "@typescript-eslint/prefer-optional-chain": "error",

    // React specific rules
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off",
    "react/display-name": "warn",
    "react/no-unescaped-entities": "off",
    "react/jsx-curly-brace-presence": [
      "error",
      {
        "props": "never",
        "children": "never"
      }
    ],
    "react/self-closing-comp": "error",
    "react/jsx-sort-props": [
      "error",
      {
        "callbacksLast": true,
        "shorthandFirst": true,
        "multiline": "last"
      }
    ],

    // React Hooks rules
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn",

    // Import/Export rules
    "import/order": [
      "error",
      {
        "groups": [
          "builtin",
          "external",
          "internal",
          "parent",
          "sibling",
          "index",
          "object",
          "type"
        ],
        "pathGroups": [
          {
            "pattern": "react",
            "group": "external",
            "position": "before"
          },
          {
            "pattern": "next/**",
            "group": "external",
            "position": "before"
          },
          {
            "pattern": "@/**",
            "group": "internal",
            "position": "before"
          }
        ],
        "pathGroupsExcludedImportTypes": ["react"],
        "newlines-between": "always",
        "alphabetize": {
          "order": "asc",
          "caseInsensitive": true
        }
      }
    ],
    "import/no-unresolved": "error",
    "import/no-cycle": "error",
    "import/no-unused-modules": "warn",

    // Accessibility rules
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/anchor-has-content": "error",
    "jsx-a11y/anchor-is-valid": "error",
    "jsx-a11y/aria-props": "error",
    "jsx-a11y/aria-proptypes": "error",
    "jsx-a11y/aria-unsupported-elements": "error",
    "jsx-a11y/click-events-have-key-events": "warn",
    "jsx-a11y/interactive-supports-focus": "error",
    "jsx-a11y/label-has-associated-control": "error",
    "jsx-a11y/no-noninteractive-element-interactions": "warn",

    // General code quality rules
    "no-console": "warn",
    "no-debugger": "error",
    "no-alert": "warn",
    "no-duplicate-imports": "error",
    "no-unused-expressions": "error",
    "prefer-const": "error",
    "no-var": "error",
    "object-shorthand": "error",
    "prefer-arrow-callback": "error",
    "prefer-template": "error",
    "template-curly-spacing": "error",
    "padding-line-between-statements": [
      "error",
      {
        "blankLine": "always",
        "prev": "*",
        "next": "return"
      },
      {
        "blankLine": "always",
        "prev": ["const", "let", "var"],
        "next": "*"
      },
      {
        "blankLine": "any",
        "prev": ["const", "let", "var"],
        "next": ["const", "let", "var"]
      }
    ]
  },
  "settings": {
    "react": {
      "version": "detect"
    },
    "import/resolver": {
      "typescript": {
        "alwaysTryTypes": true,
        "project": "./tsconfig.json"
      },
      "node": {
        "extensions": [".js", ".jsx", ".ts", ".tsx"]
      }
    }
  },
  "env": {
    "browser": true,
    "node": true,
    "es2022": true
  },
  "ignorePatterns": [
    "node_modules/",
    ".next/",
    "out/",
    "dist/",
    "build/",
    "*.config.js"
  ]
}
```

### 2. Prettier Configuration

**File**: `.prettierrc`
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "quoteProps": "as-needed",
  "jsxSingleQuote": false,
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "embeddedLanguageFormatting": "auto",
  "htmlWhitespaceSensitivity": "css",
  "insertPragma": false,
  "jsxBracketSameLine": false,
  "proseWrap": "preserve",
  "requirePragma": false,
  "vueIndentScriptAndStyle": false
}
```

**File**: `.prettierignore`
```
node_modules
.next
out
dist
build
*.config.js
*.config.ts
.env*
*.log
.DS_Store
.vscode
coverage
public
```

### 3. Package.json Dependencies and Scripts

**File**: `package.json` (add these dependencies and scripts)
```json
{
  "scripts": {
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "lint:strict": "eslint --ext .js,.jsx,.ts,.tsx .",
    "lint:strict:fix": "eslint --ext .js,.jsx,.ts,.tsx . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "type-check": "tsc --noEmit",
    "quality": "npm run type-check && npm run lint:strict && npm run format:check",
    "quality:fix": "npm run type-check && npm run lint:strict:fix && npm run format"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6.10.0",
    "@typescript-eslint/parser": "^6.10.0",
    "eslint": "^8.53.0",
    "eslint-config-next": "14.0.3",
    "eslint-config-prettier": "^9.0.0",
    "eslint-import-resolver-typescript": "^3.6.1",
    "eslint-plugin-import": "^2.29.0",
    "eslint-plugin-jsx-a11y": "^6.8.0",
    "eslint-plugin-react": "^7.33.2",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-unused-imports": "^3.0.0",
    "prettier": "^3.0.3",
    "prettier-plugin-tailwindcss": "^0.5.7"
  }
}
```

### 4. VSCode Settings Integration

**File**: `.vscode/settings.json`
```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "typescript.preferences.importModuleSpecifier": "relative",
  "typescript.suggest.autoImports": true,
  "editor.rulers": [80, 120],
  "files.associations": {
    "*.css": "tailwindcss"
  },
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ]
}
```

### 5. Git Hooks Setup (Husky)

**Install Husky and lint-staged**:
```bash
npm install --save-dev husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
```

**File**: `.lintstagedrc.json`
```json
{
  "*.{js,jsx,ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,css,md}": [
    "prettier --write"
  ]
}
```

**File**: `package.json` (add to scripts)
```json
{
  "scripts": {
    "prepare": "husky install"
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,css,md}": [
      "prettier --write"
    ]
  }
}
```

### 6. ESLint Ignore Configuration

**File**: `.eslintignore`
```
node_modules/
.next/
out/
dist/
build/
public/
*.config.js
*.config.ts
next-env.d.ts
.env*
*.log
coverage/
.nyc_output/
```

### 7. Editor Configuration

**File**: `.editorconfig`
```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml}]
indent_size = 2

[*.json]
indent_size = 2
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Linting Test
```bash
# Run ESLint check
npm run lint:strict

# Verify no linting errors
# Test auto-fix functionality
npm run lint:strict:fix
```

### 2. Formatting Test
```bash
# Check formatting
npm run format:check

# Apply formatting
npm run format

# Verify consistent formatting
```

### 3. Quality Gate Test
```bash
# Run complete quality check
npm run quality

# Verify all checks pass:
# - Type checking
# - Linting
# - Formatting
```

### 4. Pre-commit Hook Test
```bash
# Make a code change
# Attempt to commit
git add .
git commit -m "test commit"

# Verify pre-commit hooks run
# Verify code is automatically fixed
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] ESLint configured with comprehensive rules
- [x] Prettier integrated and working
- [x] TypeScript linting enabled
- [x] React and React Hooks rules active
- [x] Import sorting and organization
- [x] Pre-commit hooks functional
- [x] IDE integration complete

### Should Have
- [x] Accessibility (a11y) checks enabled
- [x] Unused imports removal
- [x] Consistent import ordering
- [x] Code quality rules enforced
- [x] Automatic formatting on save
- [x] Git hooks for quality enforcement

### Could Have
- [x] Advanced TypeScript rules
- [x] Custom code style rules
- [x] Editor configuration
- [x] Comprehensive ignore patterns
- [x] JSX prop sorting
- [x] Template literal formatting

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-003 (Tailwind CSS + shadcn/ui Setup)  
**Depends On**: TypeScript configuration and project structure  
**Blocks**: SPEC-005 (Environment Variables)  

---

## 📝 IMPLEMENTATION NOTES

### Key Configuration Decisions
1. **Rule Sets**: Comprehensive coverage of TypeScript, React, and accessibility
2. **Import Organization**: Automatic sorting and grouping of imports
3. **Code Quality**: Strict rules for maintainable code
4. **Accessibility**: Built-in a11y checks for inclusive design
5. **Automation**: Pre-commit hooks ensure quality at commit time

### ESLint Plugins Used
- `@typescript-eslint`: TypeScript-specific linting
- `react` & `react-hooks`: React best practices
- `jsx-a11y`: Accessibility checks
- `import`: Import/export organization
- `unused-imports`: Remove unused imports automatically

### Quality Workflow
1. Code written with IDE assistance
2. Auto-formatting on save
3. Linting errors highlighted in real-time
4. Pre-commit hooks run quality checks
5. CI/CD can run full quality suite

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-005 (Environment Variables Configuration)
2. ✅ Verify all linting rules work correctly
3. ✅ Test pre-commit hooks functionality
4. ✅ Update team development guidelines

---

**Specification Status**: ✅ COMPLETE  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-005-environment-variables.md