# SPEC-061: FileUpload Component
## File Upload with Drag-and-Drop

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: HIGH  
> **Estimated Time**: 6 hours  
> **Dependencies**: react-dropzone

---

## 📋 OVERVIEW

### Purpose
A comprehensive file upload component with drag-and-drop functionality, file validation, preview capabilities, and progress tracking. Supports single and multiple file uploads.

### Key Features
- ✅ Drag-and-drop interface
- ✅ Click to browse files
- ✅ Single and multiple file uploads
- ✅ File type validation
- ✅ File size validation
- ✅ Image preview thumbnails
- ✅ Upload progress tracking
- ✅ File list management
- ✅ Error handling
- ✅ React Hook Form integration
- ✅ WCAG 2.1 AA compliant

---

## 🎯 COMPONENT SPECIFICATION

### TypeScript Interfaces

```typescript
// src/components/ui/file-upload.tsx
'use client'

import * as React from 'react'
import { useDropzone, FileRejection, Accept } from 'react-dropzone'
import { Upload, X, File, Image as ImageIcon, FileText, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

// ========================================
// TYPE DEFINITIONS
// ========================================

export interface UploadedFile {
  /**
   * File object
   */
  file: File
  
  /**
   * Preview URL for images
   */
  preview?: string
  
  /**
   * Upload progress (0-100)
   */
  progress?: number
  
  /**
   * Upload status
   */
  status?: 'pending' | 'uploading' | 'success' | 'error'
  
  /**
   * Error message if upload failed
   */
  error?: string
}

export interface FileUploadProps {
  /**
   * Current file(s) value
   */
  value?: File | File[]
  
  /**
   * Callback fired when files change
   */
  onValueChange?: (files: File | File[] | undefined) => void
  
  /**
   * Label for the upload area
   */
  label?: string
  
  /**
   * Description text shown below label
   */
  description?: string
  
  /**
   * Error message to display
   */
  error?: string
  
  /**
   * Allow multiple file uploads
   */
  multiple?: boolean
  
  /**
   * Maximum number of files (when multiple is true)
   */
  maxFiles?: number
  
  /**
   * Maximum file size in bytes
   */
  maxSize?: number
  
  /**
   * Accepted file types
   * @example { 'image/*': ['.png', '.jpg', '.jpeg'] }
   */
  accept?: Accept
  
  /**
   * Show file previews
   */
  showPreview?: boolean
  
  /**
   * Custom upload handler (returns promise)
   */
  onUpload?: (files: File[]) => Promise<void>
  
  /**
   * Whether the field is required
   */
  required?: boolean
  
  /**
   * Whether the upload is disabled
   */
  disabled?: boolean
  
  /**
   * Additional CSS classes
   */
  className?: string
}

// ========================================
// HELPER FUNCTIONS
// ========================================

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

const getFileIcon = (file: File) => {
  if (file.type.startsWith('image/')) {
    return <ImageIcon className="h-4 w-4" />
  }
  if (file.type === 'application/pdf' || file.type.startsWith('text/')) {
    return <FileText className="h-4 w-4" />
  }
  return <File className="h-4 w-4" />
}

// ========================================
// FILE UPLOAD COMPONENT
// ========================================

/**
 * FileUpload Component
 * 
 * A file upload component with drag-and-drop, validation, and preview.
 * 
 * @example
 * // Basic single file upload
 * <FileUpload
 *   label="Upload document"
 *   accept={{ 'application/pdf': ['.pdf'] }}
 *   maxSize={5 * 1024 * 1024}
 *   onValueChange={setFile}
 * />
 * 
 * @example
 * // Multiple image uploads
 * <FileUpload
 *   label="Upload images"
 *   multiple
 *   maxFiles={5}
 *   accept={{ 'image/*': ['.png', '.jpg', '.jpeg'] }}
 *   showPreview
 *   onValueChange={setFiles}
 * />
 */
export const FileUpload = React.forwardRef<HTMLDivElement, FileUploadProps>(
  (
    {
      value,
      onValueChange,
      label,
      description,
      error,
      multiple = false,
      maxFiles = 1,
      maxSize,
      accept,
      showPreview = true,
      onUpload,
      required,
      disabled,
      className,
    },
    ref
  ) => {
    const [uploadedFiles, setUploadedFiles] = React.useState<UploadedFile[]>([])
    const [uploading, setUploading] = React.useState(false)
    
    const uploadId = React.useId()
    const errorId = `${uploadId}-error`
    const descriptionId = `${uploadId}-description`

    // Convert value to UploadedFile array
    React.useEffect(() => {
      if (value) {
        const files = Array.isArray(value) ? value : [value]
        setUploadedFiles(
          files.map((file) => ({
            file,
            preview: file.type.startsWith('image/') ? URL.createObjectURL(file) : undefined,
            status: 'success',
          }))
        )
      } else {
        setUploadedFiles([])
      }
    }, [value])

    const onDrop = React.useCallback(
      async (acceptedFiles: File[], rejectedFiles: FileRejection[]) => {
        if (disabled) return

        // Handle rejected files
        if (rejectedFiles.length > 0) {
          // Show error for first rejected file
          const rejection = rejectedFiles[0]
          console.error('File rejected:', rejection.errors)
          return
        }

        // Add new files
        const newFiles: UploadedFile[] = acceptedFiles.map((file) => ({
          file,
          preview: file.type.startsWith('image/') ? URL.createObjectURL(file) : undefined,
          status: 'pending' as const,
          progress: 0,
        }))

        const allFiles = multiple ? [...uploadedFiles, ...newFiles] : newFiles

        // Check max files limit
        if (multiple && maxFiles && allFiles.length > maxFiles) {
          console.error(`Maximum ${maxFiles} files allowed`)
          return
        }

        setUploadedFiles(allFiles)

        // Handle upload if custom handler provided
        if (onUpload) {
          setUploading(true)
          try {
            await onUpload(acceptedFiles)
            setUploadedFiles((prev) =>
              prev.map((f) =>
                newFiles.some((nf) => nf.file === f.file)
                  ? { ...f, status: 'success', progress: 100 }
                  : f
              )
            )
          } catch (error) {
            setUploadedFiles((prev) =>
              prev.map((f) =>
                newFiles.some((nf) => nf.file === f.file)
                  ? { ...f, status: 'error', error: 'Upload failed' }
                  : f
              )
            )
          } finally {
            setUploading(false)
          }
        }

        // Update value
        const files = allFiles.map((f) => f.file)
        onValueChange?.(multiple ? files : files[0])
      },
      [disabled, uploadedFiles, multiple, maxFiles, onUpload, onValueChange]
    )

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
      onDrop,
      accept,
      maxSize,
      multiple,
      disabled: disabled || uploading,
    })

    const removeFile = (index: number) => {
      const newFiles = uploadedFiles.filter((_, i) => i !== index)
      setUploadedFiles(newFiles)
      
      // Revoke preview URL
      if (uploadedFiles[index].preview) {
        URL.revokeObjectURL(uploadedFiles[index].preview!)
      }
      
      // Update value
      const files = newFiles.map((f) => f.file)
      onValueChange?.(files.length > 0 ? (multiple ? files : files[0]) : undefined)
    }

    // Cleanup previews on unmount
    React.useEffect(() => {
      return () => {
        uploadedFiles.forEach((file) => {
          if (file.preview) {
            URL.revokeObjectURL(file.preview)
          }
        })
      }
    }, [])

    const ariaDescribedBy = [
      description && descriptionId,
      error && errorId,
    ]
      .filter(Boolean)
      .join(' ') || undefined

    return (
      <div ref={ref} className={cn('w-full space-y-3', className)}>
        {/* Label and Description */}
        {(label || description) && (
          <div className="space-y-1">
            {label && (
              <label
                htmlFor={uploadId}
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                {label}
                {required && <span className="text-destructive ml-1">*</span>}
              </label>
            )}
            {description && (
              <p id={descriptionId} className="text-sm text-muted-foreground">
                {description}
              </p>
            )}
          </div>
        )}

        {/* Drop Zone */}
        <div
          {...getRootProps()}
          className={cn(
            'border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors',
            isDragActive && 'border-primary bg-primary/5',
            !isDragActive && 'border-border hover:border-primary/50',
            disabled && 'opacity-50 cursor-not-allowed',
            error && 'border-destructive',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2'
          )}
          aria-describedby={ariaDescribedBy}
          aria-invalid={error ? 'true' : 'false'}
          aria-required={required}
        >
          <input {...getInputProps()} id={uploadId} />
          
          <div className="flex flex-col items-center gap-2">
            <div className={cn(
              'rounded-full p-3',
              isDragActive ? 'bg-primary/10' : 'bg-muted'
            )}>
              {uploading ? (
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
              ) : (
                <Upload className="h-6 w-6 text-muted-foreground" />
              )}
            </div>
            
            <div className="space-y-1">
              <p className="text-sm font-medium">
                {isDragActive ? (
                  'Drop files here'
                ) : uploading ? (
                  'Uploading...'
                ) : (
                  <>
                    <span className="text-primary">Click to upload</span> or drag and drop
                  </>
                )}
              </p>
              
              {!uploading && (
                <p className="text-xs text-muted-foreground">
                  {accept
                    ? `Accepted: ${Object.values(accept).flat().join(', ')}`
                    : 'All file types accepted'}
                  {maxSize && ` (max ${formatFileSize(maxSize)})`}
                  {multiple && maxFiles && ` • Maximum ${maxFiles} files`}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* File List */}
        {uploadedFiles.length > 0 && (
          <div className="space-y-2">
            {uploadedFiles.map((uploadedFile, index) => (
              <div
                key={index}
                className={cn(
                  'flex items-center gap-3 p-3 rounded-lg border',
                  uploadedFile.status === 'error' && 'border-destructive bg-destructive/5'
                )}
              >
                {/* Preview or Icon */}
                {showPreview && uploadedFile.preview ? (
                  <img
                    src={uploadedFile.preview}
                    alt={uploadedFile.file.name}
                    className="h-10 w-10 rounded object-cover"
                  />
                ) : (
                  <div className="flex h-10 w-10 items-center justify-center rounded bg-muted">
                    {getFileIcon(uploadedFile.file)}
                  </div>
                )}

                {/* File Info */}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">
                    {uploadedFile.file.name}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {formatFileSize(uploadedFile.file.size)}
                    {uploadedFile.status === 'uploading' && uploadedFile.progress !== undefined && (
                      <> • {uploadedFile.progress}%</>
                    )}
                    {uploadedFile.status === 'error' && uploadedFile.error && (
                      <span className="text-destructive"> • {uploadedFile.error}</span>
                    )}
                  </p>
                  
                  {/* Progress Bar */}
                  {uploadedFile.status === 'uploading' && uploadedFile.progress !== undefined && (
                    <div className="mt-1 h-1 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-primary transition-all"
                        style={{ width: `${uploadedFile.progress}%` }}
                      />
                    </div>
                  )}
                </div>

                {/* Remove Button */}
                {uploadedFile.status !== 'uploading' && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    onClick={() => removeFile(index)}
                    disabled={disabled}
                    aria-label={`Remove ${uploadedFile.file.name}`}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Error Message */}
        {error && (
          <p id={errorId} className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}
      </div>
    )
  }
)

FileUpload.displayName = 'FileUpload'
```

---

## 📚 USAGE EXAMPLES

### Basic Single File Upload

```typescript
import { FileUpload } from '@/components/ui/file-upload'

function DocumentUpload() {
  const [file, setFile] = React.useState<File>()

  return (
    <FileUpload
      label="Upload Document"
      description="PDF files only, max 10MB"
      accept={{ 'application/pdf': ['.pdf'] }}
      maxSize={10 * 1024 * 1024}
      value={file}
      onValueChange={setFile}
    />
  )
}
```

### Multiple Image Upload with Preview

```typescript
function ImageGalleryUpload() {
  const [images, setImages] = React.useState<File[]>([])

  return (
    <FileUpload
      label="Upload Images"
      description="Upload up to 5 images (PNG, JPG, JPEG)"
      multiple
      maxFiles={5}
      accept={{ 'image/*': ['.png', '.jpg', '.jpeg'] }}
      maxSize={5 * 1024 * 1024}
      showPreview
      value={images}
      onValueChange={setImages}
    />
  )
}
```

### With Custom Upload Handler

```typescript
function ProfilePictureUpload() {
  const [picture, setPicture] = React.useState<File>()
  
  const handleUpload = async (files: File[]) => {
    const formData = new FormData()
    formData.append('file', files[0])
    
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    })
    
    if (!response.ok) {
      throw new Error('Upload failed')
    }
  }

  return (
    <FileUpload
      label="Profile Picture"
      accept={{ 'image/*': ['.png', '.jpg', '.jpeg'] }}
      maxSize={2 * 1024 * 1024}
      showPreview
      value={picture}
      onValueChange={setPicture}
      onUpload={handleUpload}
    />
  )
}
```

### With React Hook Form

```typescript
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  documents: z.array(z.instanceof(File)).min(1, 'At least one document required'),
})

function DocumentForm() {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      documents: [],
    },
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="documents"
        control={control}
        render={({ field }) => (
          <FileUpload
            label="Required Documents"
            description="Upload all required documents"
            multiple
            maxFiles={10}
            accept={{ 'application/pdf': ['.pdf'] }}
            value={field.value}
            onValueChange={field.onChange}
            error={errors.documents?.message}
            required
          />
        )}
      />
      <Button type="submit">Submit</Button>
    </form>
  )
}
```

---

## ♿ ACCESSIBILITY

### WCAG 2.1 AA Compliance
- ✅ Keyboard accessible
- ✅ Screen reader friendly
- ✅ Focus indicators visible
- ✅ ARIA labels and descriptions

### Keyboard Navigation
- **Tab**: Focus drop zone
- **Enter/Space**: Open file picker
- **Escape**: Cancel operation

---

## 🚀 IMPLEMENTATION CHECKLIST

- [ ] Install react-dropzone
- [ ] Create file-upload.tsx file
- [ ] Implement FileUpload component
- [ ] Add drag-and-drop functionality
- [ ] Add file validation
- [ ] Add image previews
- [ ] Add progress tracking
- [ ] Style with Tailwind CSS
- [ ] Write comprehensive tests
- [ ] Test accessibility
- [ ] Create Storybook stories

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0
