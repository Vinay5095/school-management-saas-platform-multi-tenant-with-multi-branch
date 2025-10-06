# SPEC-085: DataGrid Component
## Editable Data Grid with Inline Editing

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 8 hours  
> **Dependencies**: DataTable, Input, Select

---

## 📋 OVERVIEW

### Purpose
An editable data grid component that extends DataTable with inline editing capabilities, cell validation, and bulk operations.

### Key Features
- ✅ Inline cell editing
- ✅ Row editing mode
- ✅ Cell validation
- ✅ Bulk operations
- ✅ Undo/redo
- ✅ Copy/paste support
- ✅ Keyboard navigation
- ✅ Auto-save
- ✅ Change tracking
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/data-grid.tsx
'use client'

import * as React from 'react'
import { ColumnDef, Row } from '@tanstack/react-table'
import { DataTable } from '@/components/ui/data-table'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { cn } from '@/lib/utils'
import { Check, X, Edit, Save, Undo, Redo } from 'lucide-react'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface EditableCell<TData> {
  /**
   * Cell type
   */
  type: 'text' | 'number' | 'select' | 'checkbox' | 'date' | 'custom'

  /**
   * Select options (for select type)
   */
  options?: Array<{ label: string; value: string }>

  /**
   * Validation function
   */
  validate?: (value: any, row: TData) => string | undefined

  /**
   * Custom editor component
   */
  editor?: React.ComponentType<EditableCellEditorProps<TData>>

  /**
   * Read-only
   */
  readOnly?: boolean

  /**
   * Required field
   */
  required?: boolean
}

export interface EditableCellEditorProps<TData> {
  value: any
  onChange: (value: any) => void
  onSave: () => void
  onCancel: () => void
  row: Row<TData>
}

export interface DataGridProps<TData> {
  /**
   * Column definitions
   */
  columns: ColumnDef<TData>[]

  /**
   * Editable cell configuration
   */
  editableCells?: Record<string, EditableCell<TData>>

  /**
   * Table data
   */
  data: TData[]

  /**
   * Data change callback
   */
  onDataChange?: (data: TData[]) => void

  /**
   * Cell update callback
   */
  onCellUpdate?: (rowIndex: number, columnId: string, value: any) => void

  /**
   * Row update callback
   */
  onRowUpdate?: (rowIndex: number, row: TData) => void

  /**
   * Enable undo/redo
   */
  enableUndoRedo?: boolean

  /**
   * Enable auto-save
   */
  autoSave?: boolean

  /**
   * Auto-save delay (ms)
   */
  autoSaveDelay?: number

  /**
   * Enable bulk operations
   */
  enableBulkOperations?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// EDITABLE CELL COMPONENT
// ========================================

interface EditableCellComponentProps<TData> {
  row: Row<TData>
  columnId: string
  value: any
  config: EditableCell<TData>
  onUpdate: (value: any) => void
}

function EditableCellComponent<TData>({
  row,
  columnId,
  value,
  config,
  onUpdate,
}: EditableCellComponentProps<TData>) {
  const [isEditing, setIsEditing] = React.useState(false)
  const [editValue, setEditValue] = React.useState(value)
  const [error, setError] = React.useState<string>()

  React.useEffect(() => {
    setEditValue(value)
  }, [value])

  const handleSave = () => {
    if (config.validate) {
      const validationError = config.validate(editValue, row.original)
      if (validationError) {
        setError(validationError)
        return
      }
    }
    onUpdate(editValue)
    setIsEditing(false)
    setError(undefined)
  }

  const handleCancel = () => {
    setEditValue(value)
    setIsEditing(false)
    setError(undefined)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSave()
    } else if (e.key === 'Escape') {
      handleCancel()
    }
  }

  if (config.readOnly) {
    return <div className="px-2 py-1">{String(value)}</div>
  }

  if (!isEditing) {
    return (
      <div
        className="px-2 py-1 cursor-pointer hover:bg-accent rounded"
        onClick={() => setIsEditing(true)}
      >
        {config.type === 'checkbox' ? (
          <Checkbox checked={value} disabled />
        ) : (
          String(value || '')
        )}
      </div>
    )
  }

  // Custom editor
  if (config.editor) {
    const Editor = config.editor
    return (
      <Editor
        value={editValue}
        onChange={setEditValue}
        onSave={handleSave}
        onCancel={handleCancel}
        row={row}
      />
    )
  }

  // Built-in editors
  return (
    <div className="flex items-center gap-1">
      {config.type === 'select' && config.options ? (
        <Select value={editValue} onValueChange={setEditValue}>
          <SelectTrigger className="h-8 w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {config.options.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      ) : config.type === 'checkbox' ? (
        <Checkbox
          checked={editValue}
          onCheckedChange={setEditValue}
          autoFocus
        />
      ) : (
        <Input
          type={config.type === 'number' ? 'number' : 'text'}
          value={editValue}
          onChange={(e) => setEditValue(e.target.value)}
          onKeyDown={handleKeyDown}
          className={cn('h-8', error && 'border-destructive')}
          autoFocus
        />
      )}
      <Button
        size="icon"
        variant="ghost"
        className="h-8 w-8"
        onClick={handleSave}
      >
        <Check className="h-4 w-4" />
      </Button>
      <Button
        size="icon"
        variant="ghost"
        className="h-8 w-8"
        onClick={handleCancel}
      >
        <X className="h-4 w-4" />
      </Button>
      {error && (
        <div className="absolute mt-1 text-xs text-destructive">
          {error}
        </div>
      )}
    </div>
  )
}

// ========================================
// UNDO/REDO MANAGER
// ========================================

interface HistoryState<TData> {
  data: TData[]
  timestamp: number
}

class UndoRedoManager<TData> {
  private history: HistoryState<TData>[] = []
  private currentIndex = -1
  private maxHistory = 50

  push(data: TData[]) {
    // Remove any history after current index
    this.history = this.history.slice(0, this.currentIndex + 1)
    
    // Add new state
    this.history.push({ data: JSON.parse(JSON.stringify(data)), timestamp: Date.now() })
    
    // Limit history size
    if (this.history.length > this.maxHistory) {
      this.history.shift()
    } else {
      this.currentIndex++
    }
  }

  undo(): TData[] | null {
    if (this.currentIndex > 0) {
      this.currentIndex--
      return JSON.parse(JSON.stringify(this.history[this.currentIndex].data))
    }
    return null
  }

  redo(): TData[] | null {
    if (this.currentIndex < this.history.length - 1) {
      this.currentIndex++
      return JSON.parse(JSON.stringify(this.history[this.currentIndex].data))
    }
    return null
  }

  canUndo(): boolean {
    return this.currentIndex > 0
  }

  canRedo(): boolean {
    return this.currentIndex < this.history.length - 1
  }
}

// ========================================
// DATA GRID COMPONENT
// ========================================

/**
 * DataGrid Component
 * 
 * Editable data grid with inline editing.
 * 
 * @example
 * <DataGrid
 *   columns={columns}
 *   data={data}
 *   editableCells={{
 *     name: { type: 'text', required: true },
 *     status: { type: 'select', options: statusOptions },
 *   }}
 *   onDataChange={setData}
 * />
 */
export function DataGrid<TData extends Record<string, any>>({
  columns,
  editableCells = {},
  data: initialData,
  onDataChange,
  onCellUpdate,
  onRowUpdate,
  enableUndoRedo = true,
  autoSave = false,
  autoSaveDelay = 1000,
  enableBulkOperations = false,
  className,
}: DataGridProps<TData>) {
  const [data, setData] = React.useState<TData[]>(initialData)
  const [changedCells, setChangedCells] = React.useState<Set<string>>(new Set())
  const undoRedoManager = React.useRef(new UndoRedoManager<TData>())
  const autoSaveTimerRef = React.useRef<NodeJS.Timeout>()

  // Initialize history
  React.useEffect(() => {
    undoRedoManager.current.push(initialData)
  }, [])

  // Auto-save
  React.useEffect(() => {
    if (!autoSave) return

    if (autoSaveTimerRef.current) {
      clearTimeout(autoSaveTimerRef.current)
    }

    autoSaveTimerRef.current = setTimeout(() => {
      onDataChange?.(data)
    }, autoSaveDelay)

    return () => {
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current)
      }
    }
  }, [data, autoSave, autoSaveDelay])

  const handleCellUpdate = (rowIndex: number, columnId: string, value: any) => {
    const newData = [...data]
    newData[rowIndex] = { ...newData[rowIndex], [columnId]: value }
    
    setData(newData)
    setChangedCells(new Set([...changedCells, `${rowIndex}-${columnId}`]))
    
    if (enableUndoRedo) {
      undoRedoManager.current.push(newData)
    }
    
    onCellUpdate?.(rowIndex, columnId, value)
    onRowUpdate?.(rowIndex, newData[rowIndex])
    
    if (!autoSave) {
      onDataChange?.(newData)
    }
  }

  const handleUndo = () => {
    const previousData = undoRedoManager.current.undo()
    if (previousData) {
      setData(previousData)
      onDataChange?.(previousData)
    }
  }

  const handleRedo = () => {
    const nextData = undoRedoManager.current.redo()
    if (nextData) {
      setData(nextData)
      onDataChange?.(nextData)
    }
  }

  // Create editable columns
  const editableColumns: ColumnDef<TData>[] = React.useMemo(() => {
    return columns.map((column) => {
      const columnId = column.id || (column as any).accessorKey
      const editConfig = editableCells[columnId]

      if (!editConfig) return column

      return {
        ...column,
        cell: ({ row, getValue }) => (
          <EditableCellComponent
            row={row}
            columnId={columnId}
            value={getValue()}
            config={editConfig}
            onUpdate={(value) => handleCellUpdate(row.index, columnId, value)}
          />
        ),
      }
    })
  }, [columns, editableCells, data])

  return (
    <div className={cn('space-y-4', className)}>
      {enableUndoRedo && (
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleUndo}
            disabled={!undoRedoManager.current.canUndo()}
          >
            <Undo className="h-4 w-4 mr-2" />
            Undo
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleRedo}
            disabled={!undoRedoManager.current.canRedo()}
          >
            <Redo className="h-4 w-4 mr-2" />
            Redo
          </Button>
          {changedCells.size > 0 && (
            <span className="text-sm text-muted-foreground">
              {changedCells.size} cell(s) modified
            </span>
          )}
        </div>
      )}

      <DataTable columns={editableColumns} data={data} />
    </div>
  )
}
```

---

## 📚 USAGE EXAMPLES

### Basic Editable Grid

```typescript
import { DataGrid } from '@/components/ui/data-grid'

interface Product {
  id: string
  name: string
  price: number
  status: string
  inStock: boolean
}

function ProductsGrid() {
  const [products, setProducts] = React.useState<Product[]>([])

  const columns: ColumnDef<Product>[] = [
    { accessorKey: 'name', header: 'Name' },
    { accessorKey: 'price', header: 'Price' },
    { accessorKey: 'status', header: 'Status' },
    { accessorKey: 'inStock', header: 'In Stock' },
  ]

  const editableCells = {
    name: {
      type: 'text' as const,
      required: true,
      validate: (value) => {
        if (!value || value.length < 3) {
          return 'Name must be at least 3 characters'
        }
      },
    },
    price: {
      type: 'number' as const,
      validate: (value) => {
        if (value < 0) return 'Price must be positive'
      },
    },
    status: {
      type: 'select' as const,
      options: [
        { label: 'Active', value: 'active' },
        { label: 'Inactive', value: 'inactive' },
        { label: 'Discontinued', value: 'discontinued' },
      ],
    },
    inStock: {
      type: 'checkbox' as const,
    },
  }

  return (
    <DataGrid
      columns={columns}
      data={products}
      editableCells={editableCells}
      onDataChange={setProducts}
      enableUndoRedo
    />
  )
}
```

### With Auto-Save

```typescript
function AutoSaveGrid() {
  return (
    <DataGrid
      columns={columns}
      data={data}
      editableCells={editableCells}
      onDataChange={async (data) => {
        await saveToDatabase(data)
      }}
      autoSave
      autoSaveDelay={2000}
    />
  )
}
```

### With Custom Editor

```typescript
const CustomDateEditor: React.FC<EditableCellEditorProps<Product>> = ({
  value,
  onChange,
  onSave,
  onCancel,
}) => {
  return (
    <div className="flex items-center gap-1">
      <DatePicker value={value} onChange={onChange} />
      <Button size="icon" onClick={onSave}>
        <Check className="h-4 w-4" />
      </Button>
      <Button size="icon" onClick={onCancel}>
        <X className="h-4 w-4" />
      </Button>
    </div>
  )
}

const editableCells = {
  date: {
    type: 'custom' as const,
    editor: CustomDateEditor,
  },
}
```

---

## 🧪 TESTING

```typescript
describe('DataGrid', () => {
  it('renders editable cells', () => {
    render(<DataGrid columns={columns} data={data} editableCells={editableCells} />)
    const cell = screen.getByText(data[0].name)
    fireEvent.click(cell)
    expect(screen.getByRole('textbox')).toBeInTheDocument()
  })

  it('validates cell input', () => {
    render(<DataGrid columns={columns} data={data} editableCells={editableCells} />)
    // Test validation logic
  })

  it('supports undo/redo', () => {
    render(<DataGrid columns={columns} data={data} editableCells={editableCells} enableUndoRedo />)
    // Make changes
    // Click undo
    // Verify state restored
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ Focus management
- ✅ ARIA labels
- ✅ Error announcements
- ✅ Screen reader support

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Create data-grid.tsx
- [ ] Implement editable cell component
- [ ] Add cell validation
- [ ] Implement undo/redo
- [ ] Add auto-save
- [ ] Add custom editor support
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
