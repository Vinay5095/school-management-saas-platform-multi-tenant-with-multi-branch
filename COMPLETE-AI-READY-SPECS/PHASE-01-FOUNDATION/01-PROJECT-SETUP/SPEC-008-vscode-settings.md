# SPEC-008: VSCode Workspace Settings

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-008  
**Title**: VSCode Workspace Settings & Extensions  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: HIGH  
**Status**: 📝 PLANNED  
**Estimated Time**: 15 minutes  

---

## 📋 DESCRIPTION

Configure comprehensive VSCode workspace settings, recommended extensions, and development environment optimizations for the School Management SaaS project. This ensures consistent development experience across the team with proper IntelliSense, debugging, and productivity features.

## 🎯 SUCCESS CRITERIA

- [ ] VSCode workspace settings configured
- [ ] Essential extensions recommended and configured
- [ ] TypeScript IntelliSense optimized
- [ ] Debugging configuration set up
- [ ] Code formatting and linting integrated
- [ ] Tailwind CSS IntelliSense enabled
- [ ] Git integration optimized
- [ ] Team consistency ensured

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. VSCode Workspace Settings

**File**: `.vscode/settings.json`
```json
{
  "// EDITOR CONFIGURATION": "",
  "editor.fontSize": 14,
  "editor.fontFamily": "'JetBrains Mono', 'Fira Code', 'Cascadia Code', Consolas, 'Courier New', monospace",
  "editor.fontLigatures": true,
  "editor.lineHeight": 1.6,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.wordWrap": "on",
  "editor.rulers": [80, 120],
  "editor.minimap.enabled": true,
  "editor.minimap.maxColumn": 120,
  "editor.scrollBeyondLastLine": false,
  "editor.cursorBlinking": "smooth",
  "editor.cursorSmoothCaretAnimation": "on",
  "editor.smoothScrolling": true,

  "// CODE FORMATTING": "",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.formatOnType": false,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.organizeImports": "explicit",
    "source.removeUnusedImports": "explicit"
  },

  "// LANGUAGE SPECIFIC SETTINGS": "",
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.organizeImports": "explicit"
    }
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.organizeImports": "explicit"
    },
    "editor.quickSuggestions": {
      "strings": true
    }
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[javascriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.quickSuggestions": {
      "strings": true
    }
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "editor.quickSuggestions": {
      "comments": "off",
      "strings": "off",
      "other": "off"
    }
  },
  "[css]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[scss]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },

  "// TYPESCRIPT CONFIGURATION": "",
  "typescript.preferences.importModuleSpecifier": "relative",
  "typescript.suggest.autoImports": true,
  "typescript.suggest.includeCompletionsForImportStatements": true,
  "typescript.preferences.includePackageJsonAutoImports": "auto",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.inlayHints.functionLikeReturnTypes.enabled": true,
  "typescript.inlayHints.parameterNames.enabled": "literals",
  "typescript.inlayHints.parameterTypes.enabled": true,
  "typescript.inlayHints.propertyDeclarationTypes.enabled": true,
  "typescript.inlayHints.variableTypes.enabled": false,

  "// JAVASCRIPT CONFIGURATION": "",
  "javascript.preferences.importModuleSpecifier": "relative",
  "javascript.suggest.autoImports": true,
  "javascript.updateImportsOnFileMove.enabled": "always",

  "// ESLINT CONFIGURATION": "",
  "eslint.enable": true,
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "eslint.workingDirectories": [
    {
      "mode": "auto"
    }
  ],
  "eslint.codeActionsOnSave.mode": "problems",

  "// PRETTIER CONFIGURATION": "",
  "prettier.enable": true,
  "prettier.requireConfig": true,
  "prettier.configPath": ".prettierrc",

  "// TAILWIND CSS CONFIGURATION": "",
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"],
    ["clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ],
  "tailwindCSS.emmetCompletions": true,
  "tailwindCSS.validate": true,

  "// FILE ASSOCIATIONS": "",
  "files.associations": {
    "*.css": "tailwindcss",
    "*.mdx": "markdown",
    ".env*": "dotenv"
  },

  "// EMMET CONFIGURATION": "",
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html",
    "javascript": "html",
    "javascriptreact": "html"
  },
  "emmet.triggerExpansionOnTab": true,
  "emmet.showExpandedAbbreviation": "always",

  "// GIT CONFIGURATION": "",
  "git.enableSmartCommit": true,
  "git.confirmSync": false,
  "git.autofetch": true,
  "git.decorations.enabled": true,
  "git.showInlineOpenFileAction": true,
  "scm.defaultViewMode": "tree",
  "diffEditor.ignoreTrimWhitespace": false,

  "// SEARCH CONFIGURATION": "",
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/.next": true,
    "**/coverage": true,
    "**/.git": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true
  },

  "// FILES CONFIGURATION": "",
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true,
    "**/node_modules": false
  },
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.next/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/coverage/**": true
  },
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,

  "// EXPLORER CONFIGURATION": "",
  "explorer.confirmDelete": false,
  "explorer.confirmDragAndDrop": false,
  "explorer.compactFolders": false,
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.patterns": {
    "*.ts": "${capture}.js",
    "*.js": "${capture}.js.map, ${capture}.min.js, ${capture}.d.ts",
    "*.jsx": "${capture}.js",
    "*.tsx": "${capture}.ts",
    "tsconfig.json": "tsconfig.*.json",
    "package.json": "package-lock.json, yarn.lock, pnpm-lock.yaml",
    ".eslintrc.json": ".eslintrc.js, .eslintignore",
    ".prettierrc": ".prettierignore",
    "tailwind.config.js": "tailwind.config.ts, postcss.config.js",
    "next.config.js": "next.config.ts, next-env.d.ts",
    ".env": ".env.*, env.d.ts"
  },

  "// TERMINAL CONFIGURATION": "",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.fontFamily": "'JetBrains Mono', 'Fira Code', Consolas, monospace",
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",
  "terminal.integrated.scrollback": 10000,

  "// WORKBENCH CONFIGURATION": "",
  "workbench.colorTheme": "One Dark Pro Darker",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.editor.enablePreview": false,
  "workbench.editor.closeOnFileDelete": true,
  "workbench.startupEditor": "newUntitledFile",
  "workbench.tree.indent": 15,
  "workbench.list.smoothScrolling": true,

  "// BREADCRUMBS CONFIGURATION": "",
  "breadcrumbs.enabled": true,
  "breadcrumbs.showFiles": true,
  "breadcrumbs.showSymbols": true,

  "// INTELLISENSE CONFIGURATION": "",
  "editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": true
  },
  "editor.quickSuggestionsDelay": 10,
  "editor.suggestOnTriggerCharacters": true,
  "editor.acceptSuggestionOnEnter": "on",
  "editor.tabCompletion": "on",
  "editor.parameterHints.enabled": true,

  "// ERROR LENS CONFIGURATION": "",
  "errorLens.enabledDiagnosticLevels": ["error", "warning", "info"],
  "errorLens.excludeBySource": ["cspell"],

  "// AUTO RENAME TAG": "",
  "auto-rename-tag.activationOnLanguage": [
    "html",
    "xml",
    "php",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],

  "// BRACKET PAIR COLORIZER": "",
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",

  "// TODO TREE CONFIGURATION": "",
  "todo-tree.general.tags": [
    "BUG",
    "HACK",
    "FIXME",
    "TODO",
    "XXX",
    "[ ]",
    "[x]"
  ],
  "todo-tree.regex.regex": "(//|#|<!--|;|/\\*|^|^\\s*(-|\\*|\\+))\\s*($TAGS)",

  "// PATH INTELLISENSE CONFIGURATION": "",
  "path-intellisense.mappings": {
    "@": "${workspaceRoot}/src",
    "@/components": "${workspaceRoot}/src/components",
    "@/lib": "${workspaceRoot}/src/lib",
    "@/hooks": "${workspaceRoot}/src/hooks",
    "@/types": "${workspaceRoot}/src/types",
    "@/utils": "${workspaceRoot}/src/lib"
  }
}
```

### 2. Recommended Extensions

**File**: `.vscode/extensions.json`
```json
{
  "recommendations": [
    "// ESSENTIAL EXTENSIONS": "",
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    
    "// REACT & NEXT.JS": "",
    "ms-vscode.vscode-react-javascript",
    "burkeholland.simple-react-snippets",
    "dsznajder.es7-react-js-snippets",
    
    "// UI & THEMING": "",
    "zhuangtongfa.material-theme",
    "pkief.material-icon-theme",
    "oderwat.indent-rainbow",
    "usernamehw.errorlens",
    
    "// PRODUCTIVITY": "",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "gruntfuggly.todo-tree",
    "streetsidesoftware.code-spell-checker",
    "wayou.vscode-todo-highlight",
    
    "// GIT & VERSION CONTROL": "",
    "eamodio.gitlens",
    "mhutchie.git-graph",
    "donjayamanne.githistory",
    
    "// DATABASE & API": "",
    "ms-vscode.vscode-json",
    "humao.rest-client",
    "rangav.vscode-thunder-client",
    
    "// MARKDOWN & DOCUMENTATION": "",
    "yzhang.markdown-all-in-one",
    "davidanson.vscode-markdownlint",
    "bierner.markdown-mermaid",
    
    "// TESTING": "",
    "orta.vscode-jest",
    "ms-playwright.playwright",
    
    "// UTILITY": "",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-json5",
    "bradlc.vscode-tailwindcss",
    
    "// DOCKER & DEPLOYMENT": "",
    "ms-azuretools.vscode-docker",
    "ms-vscode-remote.remote-containers",
    
    "// AI & COPILOT": "",
    "github.copilot",
    "github.copilot-chat"
  ],
  "unwantedRecommendations": [
    "ms-vscode.vscode-typescript",
    "hookyqr.beautify",
    "ms-vscode.vscode-css"
  ]
}
```

### 3. Launch Configuration (Debugging)

**File**: `.vscode/launch.json`
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug server-side",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/next",
      "args": ["dev"],
      "console": "integratedTerminal",
      "env": {
        "NODE_OPTIONS": "--inspect"
      }
    },
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}",
      "sourceMapPathOverrides": {
        "webpack://_N_E/*": "${webRoot}/*",
        "webpack:///./*": "${webRoot}/*",
        "webpack:///./~/*": "${webRoot}/node_modules/*"
      }
    },
    {
      "name": "Next.js: debug full stack",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/next",
      "args": ["dev"],
      "console": "integratedTerminal",
      "serverReadyAction": {
        "pattern": "started server on .+, url: (https?://.+)",
        "uriFormat": "%s",
        "action": "debugWithChrome"
      }
    },
    {
      "name": "Debug Jest Tests",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["--runInBand", "--no-cache", "--no-coverage"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "disableOptimisticBPs": true,
      "windows": {
        "program": "${workspaceFolder}/node_modules/jest/bin/jest"
      }
    },
    {
      "name": "Debug Current Jest Test",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["${relativeFile}", "--runInBand", "--no-cache", "--no-coverage"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "disableOptimisticBPs": true,
      "windows": {
        "program": "${workspaceFolder}/node_modules/jest/bin/jest"
      }
    },
    {
      "name": "Debug Playwright Tests",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/playwright",
      "args": ["test", "--debug"],
      "console": "integratedTerminal"
    }
  ]
}
```

### 4. Tasks Configuration

**File**: `.vscode/tasks.json`
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start Development Server",
      "type": "shell",
      "command": "npm run dev",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": true,
        "clear": false
      },
      "isBackground": true,
      "problemMatcher": {
        "owner": "typescript",
        "source": "ts",
        "applyTo": "closedDocuments",
        "fileLocation": ["relative", "${cwd}"],
        "pattern": {
          "regexp": "\\b(ERROR)\\(([^)]+)\\)\\s+(.+)$",
          "severity": 1,
          "file": 2,
          "message": 3
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": ".*Local:.*",
          "endsPattern": ".*ready.*"
        }
      }
    },
    {
      "label": "Build Project",
      "type": "shell",
      "command": "npm run build",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$tsc"]
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "npm test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Run E2E Tests",
      "type": "shell",
      "command": "npm run test:e2e",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Type Check",
      "type": "shell",
      "command": "npm run type-check",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$tsc"]
    },
    {
      "label": "Lint",
      "type": "shell",
      "command": "npm run lint:strict",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$eslint-stylish"]
    },
    {
      "label": "Format Code",
      "type": "shell",
      "command": "npm run format",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Quality Check",
      "type": "shell",
      "command": "npm run quality",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "dependsOrder": "sequence",
      "dependsOn": ["Type Check", "Lint", "Run Tests"]
    },
    {
      "label": "Generate Database Types",
      "type": "shell",
      "command": "npm run db:generate",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Start Storybook",
      "type": "shell",
      "command": "npm run storybook",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "isBackground": true,
      "problemMatcher": {
        "pattern": {
          "regexp": "."
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": ".*info.*",
          "endsPattern": ".*Local:.*"
        }
      }
    }
  ]
}
```

### 5. Code Snippets

**File**: `.vscode/snippets.code-snippets`
```json
{
  "React Functional Component": {
    "prefix": ["rfc", "component"],
    "body": [
      "import React from 'react';",
      "",
      "interface ${1:ComponentName}Props {",
      "  ${2:// props}",
      "}",
      "",
      "export function ${1:ComponentName}({ ${3:props} }: ${1:ComponentName}Props) {",
      "  return (",
      "    <div>",
      "      ${4:// component content}",
      "    </div>",
      "  );",
      "}",
      "",
      "export default ${1:ComponentName};"
    ],
    "description": "Create a React functional component with TypeScript"
  },
  "React Hook": {
    "prefix": ["hook", "usehook"],
    "body": [
      "import { useState, useEffect } from 'react';",
      "",
      "export function use${1:HookName}(${2:params}) {",
      "  const [${3:state}, set${3/(.*)/${3:/capitalize}/}] = useState${4:<${5:type}>}(${6:initialValue});",
      "",
      "  useEffect(() => {",
      "    ${7:// effect logic}",
      "  }, [${8:dependencies}]);",
      "",
      "  return {",
      "    ${3:state},",
      "    set${3/(.*)/${3:/capitalize}/},",
      "    ${9:// other returns}",
      "  };",
      "}"
    ],
    "description": "Create a custom React hook"
  },
  "Next.js Page Component": {
    "prefix": ["page", "nextpage"],
    "body": [
      "import type { NextPage } from 'next';",
      "import { NextSeo } from 'next-seo';",
      "",
      "const ${1:PageName}Page: NextPage = () => {",
      "  return (",
      "    <>",
      "      <NextSeo",
      "        title=\"${2:Page Title}\"",
      "        description=\"${3:Page description}\"",
      "      />",
      "      <div>",
      "        <h1>${2:Page Title}</h1>",
      "        ${4:// page content}",
      "      </div>",
      "    </>",
      "  );",
      "};",
      "",
      "export default ${1:PageName}Page;"
    ],
    "description": "Create a Next.js page component"
  },
  "API Route Handler": {
    "prefix": ["api", "apihandler"],
    "body": [
      "import type { NextApiRequest, NextApiResponse } from 'next';",
      "",
      "export default async function handler(",
      "  req: NextApiRequest,",
      "  res: NextApiResponse",
      ") {",
      "  if (req.method === '${1:GET}') {",
      "    try {",
      "      ${2:// API logic}",
      "      ",
      "      res.status(200).json({ ${3:data} });",
      "    } catch (error) {",
      "      console.error('API Error:', error);",
      "      res.status(500).json({ error: 'Internal Server Error' });",
      "    }",
      "  } else {",
      "    res.setHeader('Allow', ['${1:GET}']);",
      "    res.status(405).end(`Method ${req.method} Not Allowed`);",
      "  }",
      "}"
    ],
    "description": "Create a Next.js API route handler"
  },
  "Supabase Query": {
    "prefix": ["supabase", "query"],
    "body": [
      "const { data, error } = await supabase",
      "  .from('${1:table_name}')",
      "  .${2:select}('${3:*}')",
      "  ${4:.eq('column', value)}",
      "  ${5:.single()};",
      "",
      "if (error) {",
      "  console.error('Database error:', error);",
      "  throw error;",
      "}",
      "",
      "return data;"
    ],
    "description": "Create a Supabase query"
  },
  "React Query Hook": {
    "prefix": ["reactquery", "usequery"],
    "body": [
      "import { useQuery } from '@tanstack/react-query';",
      "",
      "export function use${1:QueryName}(${2:params}) {",
      "  return useQuery({",
      "    queryKey: ['${3:queryKey}', ${4:params}],",
      "    queryFn: async () => {",
      "      ${5:// fetch logic}",
      "    },",
      "    ${6:// options}",
      "  });",
      "}"
    ],
    "description": "Create a React Query hook"
  }
}
```

### 6. Workspace File

**File**: `school-management-saas.code-workspace`
```json
{
  "folders": [
    {
      "name": "School Management SaaS",
      "path": "."
    }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true,
      "**/.next": true,
      "**/dist": true,
      "**/build": true,
      "**/.git": false
    },
    "search.exclude": {
      "**/node_modules": true,
      "**/.next": true,
      "**/dist": true,
      "**/build": true,
      "**/coverage": true
    }
  },
  "extensions": {
    "recommendations": [
      "ms-vscode.vscode-typescript-next",
      "bradlc.vscode-tailwindcss",
      "esbenp.prettier-vscode",
      "dbaeumer.vscode-eslint",
      "github.copilot"
    ]
  },
  "tasks": {
    "version": "2.0.0",
    "tasks": [
      {
        "label": "Install Dependencies",
        "type": "shell",
        "command": "npm install",
        "group": "build",
        "presentation": {
          "echo": true,
          "reveal": "always",
          "focus": false,
          "panel": "shared"
        }
      }
    ]
  }
}
```

### 7. Development Documentation

**File**: `docs/VSCODE_SETUP.md`
```markdown
# VSCode Development Setup

## 🚀 Quick Setup

1. **Install VSCode**: Download from [code.visualstudio.com](https://code.visualstudio.com/)

2. **Open Project**: 
   ```bash
   code school-management-saas.code-workspace
   ```

3. **Install Extensions**: VSCode will prompt to install recommended extensions

4. **Configure Settings**: Settings are automatically applied from `.vscode/settings.json`

## 📦 Essential Extensions

### Core Development
- **TypeScript**: `ms-vscode.vscode-typescript-next`
- **Tailwind CSS**: `bradlc.vscode-tailwindcss`  
- **Prettier**: `esbenp.prettier-vscode`
- **ESLint**: `dbaeumer.vscode-eslint`

### React & Next.js
- **React Snippets**: `dsznajder.es7-react-js-snippets`
- **Auto Rename Tag**: `formulahendry.auto-rename-tag`

### Productivity
- **GitLens**: `eamodio.gitlens`
- **Error Lens**: `usernamehw.errorlens`
- **TODO Tree**: `gruntfuggly.todo-tree`
- **Path Intellisense**: `christian-kohler.path-intellisense`

### AI Assistance
- **GitHub Copilot**: `github.copilot`
- **GitHub Copilot Chat**: `github.copilot-chat`

## 🔧 Key Features Configured

### Code Formatting
- **Auto format on save**: Prettier + ESLint
- **Import organization**: Automatic import sorting
- **Trailing whitespace removal**: Clean files

### TypeScript Intelligence
- **Path mapping**: `@/` aliases configured
- **Auto imports**: Relative imports preferred
- **Type hints**: Inline parameter and return types
- **Error highlighting**: Real-time error detection

### Tailwind CSS
- **IntelliSense**: Class name completion
- **Hover preview**: See generated CSS
- **Custom regex**: Support for `cn()`, `cva()` functions
- **Emmet integration**: Fast HTML generation

### Debugging
- **Next.js debugging**: Server and client-side
- **Jest test debugging**: Individual and all tests
- **Playwright debugging**: E2E test debugging

## 🎨 Recommended Theme & Icons

- **Theme**: One Dark Pro Darker
- **Icons**: Material Icon Theme
- **Font**: JetBrains Mono (with ligatures)

## ⌨️ Useful Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Command Palette | `Ctrl+Shift+P` |
| Quick Open | `Ctrl+P` |
| Go to Symbol | `Ctrl+Shift+O` |
| Go to Definition | `F12` |
| Format Document | `Shift+Alt+F` |
| Toggle Terminal | `Ctrl+`` |
| Multi-cursor | `Ctrl+Alt+↓` |
| Rename Symbol | `F2` |

## 🏃‍♂️ Quick Commands

### Via Command Palette (`Ctrl+Shift+P`)
- `TypeScript: Restart TS Server`
- `Developer: Reload Window`
- `Prettier: Format Document`
- `ESLint: Fix all auto-fixable Problems`

### Via Terminal (`Ctrl+`` )
```bash
# Start development
npm run dev

# Run tests
npm test

# Type check
npm run type-check

# Format code
npm run format
```

## 🚨 Troubleshooting

### TypeScript Issues
1. Restart TypeScript server: `Ctrl+Shift+P` → "TypeScript: Restart TS Server"
2. Check `tsconfig.json` for path mapping issues
3. Verify all dependencies are installed

### ESLint Issues
1. Check `.eslintrc.json` configuration
2. Restart ESLint server: `Ctrl+Shift+P` → "ESLint: Restart ESLint Server"
3. Verify file is included in ESLint scope

### Prettier Issues
1. Check `.prettierrc` configuration exists
2. Set Prettier as default formatter
3. Enable "Format on Save" in settings

### Tailwind Issues
1. Restart Tailwind CSS server
2. Check `tailwind.config.js` configuration
3. Verify CSS file imports Tailwind directives

## 🔄 Syncing Settings

Settings are stored in `.vscode/settings.json` and committed to the repository. This ensures consistent development experience across the team.

### Personal Settings Override
Create `.vscode/settings.local.json` for personal preferences (this file is gitignored).

### Team Settings Update
Modify `.vscode/settings.json` and commit changes to update team settings.
```

---

## 🧪 TESTING REQUIREMENTS

### 1. VSCode Configuration Test
```bash
# Open project in VSCode
code school-management-saas.code-workspace

# Verify settings are applied
# Check recommended extensions appear
# Test IntelliSense functionality
```

### 2. Extension Functionality Test
```bash
# Test TypeScript IntelliSense
# Verify Tailwind CSS completions
# Check ESLint error highlighting
# Test Prettier formatting
# Verify debugging configurations
```

### 3. Development Workflow Test
```bash
# Create a new component
# Test auto-import functionality
# Verify code formatting on save
# Test debugging breakpoints
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] VSCode workspace settings configured
- [x] Essential extensions recommended  
- [x] TypeScript IntelliSense optimized
- [x] Code formatting integration
- [x] Debugging configurations set up
- [x] Tailwind CSS IntelliSense enabled
- [x] Path mapping configured

### Should Have
- [x] Custom code snippets created
- [x] Task configurations set up
- [x] Git integration optimized
- [x] File nesting patterns configured
- [x] Search and exclude patterns
- [x] Terminal customization
- [x] Theme and icon recommendations

### Could Have
- [x] Advanced debugging configurations
- [x] Workspace file created
- [x] Development documentation
- [x] Troubleshooting guide
- [x] Team synchronization setup
- [x] Performance optimizations
- [x] AI assistant integration

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-007 (Git Configuration & Hooks)  
**Depends On**: All previous project setup specifications  
**Blocks**: Phase 1 Database specifications  

---

## 📝 IMPLEMENTATION NOTES

### Key Configuration Areas
1. **Editor Settings**: Font, formatting, rulers, minimap
2. **Language Support**: TypeScript, React, CSS, JSON
3. **Extension Integration**: ESLint, Prettier, Tailwind
4. **Debugging Setup**: Next.js, Jest, Playwright
5. **Productivity Features**: Snippets, tasks, shortcuts

### Development Experience Focus
- **Consistency**: Team-wide settings synchronization
- **Productivity**: Shortcuts, snippets, automation  
- **Quality**: Linting, formatting, type checking
- **Intelligence**: Auto-completion, imports, hints
- **Debugging**: Comprehensive debugging support

### Extension Strategy
- **Core**: Essential for all developers
- **Recommended**: Helpful for productivity
- **Optional**: Personal preference extensions
- **Unwanted**: Extensions that conflict

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Project Setup Phase Complete (SPEC-001 through SPEC-008)
2. ✅ Team onboarding with VSCode setup
3. ✅ Move to Phase 1 Database specifications (SPEC-009)
4. ✅ Verify all development tools working

---

**Specification Status**: 📝 PLANNED  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-009-multi-tenant-architecture.md (Phase 1 Database)