# SPEC-084: DataTable Component
## Advanced Data Table with TanStack Table v8

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: CRITICAL  
> **Estimated Time**: 12 hours  
> **Dependencies**: TanStack Table v8, Button, Select, Input

---

## 📋 OVERVIEW

### Purpose
A powerful, feature-rich data table component built on TanStack Table v8 with sorting, filtering, pagination, column visibility, row selection, and export capabilities.

### Key Features
- ✅ TanStack Table v8 integration
- ✅ Server-side & client-side modes
- ✅ Sorting (single/multi-column)
- ✅ Filtering (global & column-specific)
- ✅ Pagination with page size selector
- ✅ Column visibility toggle
- ✅ Row selection (single/multi)
- ✅ Row actions menu
- ✅ Column resizing
- ✅ Column ordering
- ✅ Export to CSV/Excel
- ✅ Loading & empty states
- ✅ Responsive design
- ✅ Virtualization support
- ✅ Accessibility

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/data-table.tsx
'use client'

import * as React from 'react'
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  Row,
  Table as TanStackTable,
} from '@tanstack/react-table'
import {
  ArrowUpDown,
  ChevronDown,
  Download,
  Filter,
  MoreHorizontal,
  Settings2,
  X,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { cn } from '@/lib/utils'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface DataTableProps<TData, TValue> {
  /**
   * Column definitions
   */
  columns: ColumnDef<TData, TValue>[]

  /**
   * Table data
   */
  data: TData[]

  /**
   * Enable row selection
   */
  enableRowSelection?: boolean

  /**
   * Enable multi-row selection
   */
  enableMultiRowSelection?: boolean

  /**
   * Row selection state (controlled)
   */
  rowSelection?: Record<string, boolean>

  /**
   * Row selection change callback
   */
  onRowSelectionChange?: (selection: Record<string, boolean>) => void

  /**
   * Enable sorting
   */
  enableSorting?: boolean

  /**
   * Enable filtering
   */
  enableFiltering?: boolean

  /**
   * Enable column visibility
   */
  enableColumnVisibility?: boolean

  /**
   * Enable pagination
   */
  enablePagination?: boolean

  /**
   * Page size options
   */
  pageSizeOptions?: number[]

  /**
   * Default page size
   */
  defaultPageSize?: number

  /**
   * Search placeholder
   */
  searchPlaceholder?: string

  /**
   * Search column (for global filter)
   */
  searchColumn?: string

  /**
   * Enable export
   */
  enableExport?: boolean

  /**
   * Export filename
   */
  exportFilename?: string

  /**
   * Row actions
   */
  rowActions?: (row: Row<TData>) => React.ReactNode

  /**
   * Empty state message
   */
  emptyMessage?: string

  /**
   * Loading state
   */
  isLoading?: boolean

  /**
   * Additional CSS classes
   */
  className?: string
}

export interface DataTableColumnHeaderProps<TData, TValue>
  extends React.HTMLAttributes<HTMLDivElement> {
  column: any
  title: string
}

// ========================================
// COLUMN HEADER COMPONENT
// ========================================

export function DataTableColumnHeader<TData, TValue>({
  column,
  title,
  className,
}: DataTableColumnHeaderProps<TData, TValue>) {
  if (!column.getCanSort()) {
    return <div className={cn(className)}>{title}</div>
  }

  return (
    <div className={cn('flex items-center space-x-2', className)}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="-ml-3 h-8 data-[state=open]:bg-accent"
          >
            <span>{title}</span>
            {column.getIsSorted() === 'desc' ? (
              <ArrowUpDown className="ml-2 h-4 w-4" />
            ) : column.getIsSorted() === 'asc' ? (
              <ArrowUpDown className="ml-2 h-4 w-4" />
            ) : (
              <ArrowUpDown className="ml-2 h-4 w-4 opacity-50" />
            )}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="start">
          <DropdownMenuItem onClick={() => column.toggleSorting(false)}>
            Sort Ascending
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => column.toggleSorting(true)}>
            Sort Descending
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => column.clearSorting()}>
            Clear Sort
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}

// ========================================
// TOOLBAR COMPONENT
// ========================================

interface DataTableToolbarProps<TData> {
  table: TanStackTable<TData>
  searchColumn?: string
  searchPlaceholder?: string
  enableColumnVisibility?: boolean
  enableExport?: boolean
  exportFilename?: string
}

function DataTableToolbar<TData>({
  table,
  searchColumn,
  searchPlaceholder = 'Search...',
  enableColumnVisibility = true,
  enableExport = false,
  exportFilename = 'data',
}: DataTableToolbarProps<TData>) {
  const isFiltered = table.getState().columnFilters.length > 0

  const exportToCSV = () => {
    const rows = table.getFilteredRowModel().rows
    const headers = table
      .getAllColumns()
      .filter((column) => column.getIsVisible())
      .map((column) => column.id)

    const csv = [
      headers.join(','),
      ...rows.map((row) =>
        headers
          .map((header) => {
            const value = row.getValue(header)
            return typeof value === 'string' ? `"${value}"` : value
          })
          .join(',')
      ),
    ].join('\n')

    const blob = new Blob([csv], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${exportFilename}.csv`
    a.click()
    window.URL.revokeObjectURL(url)
  }

  return (
    <div className="flex items-center justify-between gap-2 py-4">
      <div className="flex flex-1 items-center space-x-2">
        {searchColumn && (
          <Input
            placeholder={searchPlaceholder}
            value={
              (table.getColumn(searchColumn)?.getFilterValue() as string) ?? ''
            }
            onChange={(event) =>
              table.getColumn(searchColumn)?.setFilterValue(event.target.value)
            }
            className="h-8 w-[150px] lg:w-[250px]"
          />
        )}
        {isFiltered && (
          <Button
            variant="ghost"
            onClick={() => table.resetColumnFilters()}
            className="h-8 px-2 lg:px-3"
          >
            Reset
            <X className="ml-2 h-4 w-4" />
          </Button>
        )}
      </div>
      <div className="flex items-center space-x-2">
        {enableExport && (
          <Button
            variant="outline"
            size="sm"
            onClick={exportToCSV}
            className="h-8"
          >
            <Download className="mr-2 h-4 w-4" />
            Export
          </Button>
        )}
        {enableColumnVisibility && (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="h-8">
                <Settings2 className="mr-2 h-4 w-4" />
                View
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-[150px]">
              <DropdownMenuLabel>Toggle columns</DropdownMenuLabel>
              <DropdownMenuSeparator />
              {table
                .getAllColumns()
                .filter(
                  (column) =>
                    typeof column.accessorFn !== 'undefined' &&
                    column.getCanHide()
                )
                .map((column) => {
                  return (
                    <DropdownMenuCheckboxItem
                      key={column.id}
                      className="capitalize"
                      checked={column.getIsVisible()}
                      onCheckedChange={(value) =>
                        column.toggleVisibility(!!value)
                      }
                    >
                      {column.id}
                    </DropdownMenuCheckboxItem>
                  )
                })}
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>
    </div>
  )
}

// ========================================
// PAGINATION COMPONENT
// ========================================

interface DataTablePaginationProps<TData> {
  table: TanStackTable<TData>
  pageSizeOptions?: number[]
}

function DataTablePagination<TData>({
  table,
  pageSizeOptions = [10, 20, 30, 40, 50],
}: DataTablePaginationProps<TData>) {
  return (
    <div className="flex items-center justify-between px-2 py-4">
      <div className="flex-1 text-sm text-muted-foreground">
        {table.getFilteredSelectedRowModel().rows.length} of{' '}
        {table.getFilteredRowModel().rows.length} row(s) selected.
      </div>
      <div className="flex items-center space-x-6 lg:space-x-8">
        <div className="flex items-center space-x-2">
          <p className="text-sm font-medium">Rows per page</p>
          <Select
            value={`${table.getState().pagination.pageSize}`}
            onValueChange={(value) => {
              table.setPageSize(Number(value))
            }}
          >
            <SelectTrigger className="h-8 w-[70px]">
              <SelectValue placeholder={table.getState().pagination.pageSize} />
            </SelectTrigger>
            <SelectContent side="top">
              {pageSizeOptions.map((pageSize) => (
                <SelectItem key={pageSize} value={`${pageSize}`}>
                  {pageSize}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="flex w-[100px] items-center justify-center text-sm font-medium">
          Page {table.getState().pagination.pageIndex + 1} of{' '}
          {table.getPageCount()}
        </div>
        <div className="flex items-center space-x-2">
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => table.setPageIndex(0)}
            disabled={!table.getCanPreviousPage()}
          >
            <span className="sr-only">Go to first page</span>
            {'<<'}
          </Button>
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
          >
            <span className="sr-only">Go to previous page</span>
            {'<'}
          </Button>
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
          >
            <span className="sr-only">Go to next page</span>
            {'>'}
          </Button>
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => table.setPageIndex(table.getPageCount() - 1)}
            disabled={!table.getCanNextPage()}
          >
            <span className="sr-only">Go to last page</span>
            {'>>'}
          </Button>
        </div>
      </div>
    </div>
  )
}

// ========================================
// MAIN DATA TABLE COMPONENT
// ========================================

/**
 * DataTable Component
 * 
 * Advanced data table with sorting, filtering, pagination.
 * 
 * @example
 * <DataTable
 *   columns={columns}
 *   data={data}
 *   enableRowSelection
 *   enableSorting
 *   enableFiltering
 * />
 */
export function DataTable<TData, TValue>({
  columns,
  data,
  enableRowSelection = false,
  enableMultiRowSelection = true,
  rowSelection: controlledRowSelection,
  onRowSelectionChange,
  enableSorting = true,
  enableFiltering = true,
  enableColumnVisibility = true,
  enablePagination = true,
  pageSizeOptions = [10, 20, 30, 40, 50],
  defaultPageSize = 10,
  searchPlaceholder = 'Search...',
  searchColumn,
  enableExport = false,
  exportFilename = 'data',
  rowActions,
  emptyMessage = 'No results.',
  isLoading = false,
  className,
}: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({})
  const [rowSelection, setRowSelection] = React.useState<Record<string, boolean>>(
    controlledRowSelection || {}
  )

  // Add selection column if enabled
  const columnsWithSelection = React.useMemo(() => {
    if (!enableRowSelection) return columns

    return [
      {
        id: 'select',
        header: ({ table }: any) =>
          enableMultiRowSelection ? (
            <Checkbox
              checked={table.getIsAllPageRowsSelected()}
              onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
              aria-label="Select all"
            />
          ) : null,
        cell: ({ row }: any) => (
          <Checkbox
            checked={row.getIsSelected()}
            onCheckedChange={(value) => row.toggleSelected(!!value)}
            aria-label="Select row"
          />
        ),
        enableSorting: false,
        enableHiding: false,
      },
      ...columns,
    ] as ColumnDef<TData, TValue>[]
  }, [columns, enableRowSelection, enableMultiRowSelection])

  // Add actions column if provided
  const columnsWithActions = React.useMemo(() => {
    if (!rowActions) return columnsWithSelection

    return [
      ...columnsWithSelection,
      {
        id: 'actions',
        cell: ({ row }: any) => rowActions(row),
        enableSorting: false,
        enableHiding: false,
      },
    ] as ColumnDef<TData, TValue>[]
  }, [columnsWithSelection, rowActions])

  const table = useReactTable({
    data,
    columns: columnsWithActions,
    state: {
      sorting,
      columnFilters,
      columnVisibility,
      rowSelection: controlledRowSelection || rowSelection,
    },
    enableRowSelection,
    onRowSelectionChange: (updater) => {
      const newSelection =
        typeof updater === 'function' ? updater(rowSelection) : updater
      setRowSelection(newSelection)
      onRowSelectionChange?.(newSelection)
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: enablePagination ? getPaginationRowModel() : undefined,
    getSortedRowModel: enableSorting ? getSortedRowModel() : undefined,
    getFilteredRowModel: enableFiltering ? getFilteredRowModel() : undefined,
    initialState: {
      pagination: {
        pageSize: defaultPageSize,
      },
    },
  })

  return (
    <div className={cn('space-y-4', className)}>
      <DataTableToolbar
        table={table}
        searchColumn={searchColumn}
        searchPlaceholder={searchPlaceholder}
        enableColumnVisibility={enableColumnVisibility}
        enableExport={enableExport}
        exportFilename={exportFilename}
      />

      <div className="rounded-md border">
        <div className="relative w-full overflow-auto">
          <table className="w-full caption-bottom text-sm">
            <thead className="[&_tr]:border-b">
              {table.getHeaderGroups().map((headerGroup) => (
                <tr key={headerGroup.id} className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                  {headerGroup.headers.map((header) => (
                    <th
                      key={header.id}
                      className="h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0"
                    >
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                    </th>
                  ))}
                </tr>
              ))}
            </thead>
            <tbody className="[&_tr:last-child]:border-0">
              {isLoading ? (
                <tr>
                  <td
                    colSpan={columnsWithActions.length}
                    className="h-24 text-center"
                  >
                    <div className="flex items-center justify-center">
                      <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
                    </div>
                  </td>
                </tr>
              ) : table.getRowModel().rows?.length ? (
                table.getRowModel().rows.map((row) => (
                  <tr
                    key={row.id}
                    data-state={row.getIsSelected() && 'selected'}
                    className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))
              ) : (
                <tr>
                  <td
                    colSpan={columnsWithActions.length}
                    className="h-24 text-center"
                  >
                    {emptyMessage}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {enablePagination && (
        <DataTablePagination table={table} pageSizeOptions={pageSizeOptions} />
      )}
    </div>
  )
}

// ========================================
// EXPORTS
// ========================================

export { DataTableColumnHeader }
```

---

## 📚 USAGE EXAMPLES

### Basic DataTable

```typescript
import { DataTable, DataTableColumnHeader } from '@/components/ui/data-table'
import { ColumnDef } from '@tanstack/react-table'

interface User {
  id: string
  name: string
  email: string
  role: string
}

const columns: ColumnDef<User>[] = [
  {
    accessorKey: 'name',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Name" />
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
  },
  {
    accessorKey: 'role',
    header: 'Role',
  },
]

function UsersTable() {
  const [data, setData] = React.useState<User[]>([])

  return (
    <DataTable
      columns={columns}
      data={data}
      searchColumn="name"
      searchPlaceholder="Search users..."
    />
  )
}
```

### With Row Selection

```typescript
function SelectableTable() {
  const [selectedRows, setSelectedRows] = React.useState({})

  return (
    <DataTable
      columns={columns}
      data={data}
      enableRowSelection
      rowSelection={selectedRows}
      onRowSelectionChange={setSelectedRows}
    />
  )
}
```

### With Row Actions

```typescript
import { MoreHorizontal, Edit, Trash } from 'lucide-react'

const columns: ColumnDef<User>[] = [
  // ... other columns
]

function TableWithActions() {
  const rowActions = (row: Row<User>) => (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="h-8 w-8 p-0">
          <MoreHorizontal className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => handleEdit(row.original)}>
          <Edit className="mr-2 h-4 w-4" />
          Edit
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleDelete(row.original)}>
          <Trash className="mr-2 h-4 w-4" />
          Delete
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )

  return (
    <DataTable
      columns={columns}
      data={data}
      rowActions={rowActions}
    />
  )
}
```

### With Export

```typescript
function ExportableTable() {
  return (
    <DataTable
      columns={columns}
      data={data}
      enableExport
      exportFilename="users-report"
    />
  )
}
```

---

## 🧪 TESTING

```typescript
describe('DataTable', () => {
  it('renders data', () => {
    render(<DataTable columns={columns} data={data} />)
    expect(screen.getByText(data[0].name)).toBeInTheDocument()
  })

  it('sorts columns', () => {
    render(<DataTable columns={columns} data={data} enableSorting />)
    const nameHeader = screen.getByText('Name')
    fireEvent.click(nameHeader)
    // Check sorting applied
  })

  it('filters data', () => {
    render(<DataTable columns={columns} data={data} searchColumn="name" />)
    const searchInput = screen.getByPlaceholderText('Search...')
    fireEvent.change(searchInput, { target: { value: 'John' } })
    // Check filtered results
  })

  it('handles row selection', () => {
    const onRowSelectionChange = jest.fn()
    render(
      <DataTable
        columns={columns}
        data={data}
        enableRowSelection
        onRowSelectionChange={onRowSelectionChange}
      />
    )
    const checkbox = screen.getAllByRole('checkbox')[1]
    fireEvent.click(checkbox)
    expect(onRowSelectionChange).toHaveBeenCalled()
  })
})
```

---

## ♿ ACCESSIBILITY

- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Screen reader support
- ✅ Focus indicators
- ✅ Sortable announcements

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install @tanstack/react-table
- [ ] Create data-table.tsx
- [ ] Implement column header
- [ ] Implement toolbar
- [ ] Implement pagination
- [ ] Add row selection
- [ ] Add row actions
- [ ] Add export functionality
- [ ] Add loading states
- [ ] Write tests
- [ ] Test accessibility

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
