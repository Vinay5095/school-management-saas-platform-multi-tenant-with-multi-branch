# SPEC-130: Documentation Management
## Comprehensive Documentation System and Knowledge Base

> **Status**: ✅ READY FOR IMPLEMENTATION  
> **Priority**: MEDIUM  
> **Estimated Time**: 5-6 hours  
> **Dependencies**: SPEC-116, Phase 1

---

## 📋 OVERVIEW

### Purpose
Comprehensive documentation management system providing centralized knowledge base, API documentation, user guides, admin documentation, and collaborative documentation tools for the entire platform.

### Key Features
- ✅ Interactive documentation editor
- ✅ Multi-format content support (Markdown, HTML, Rich Text)
- ✅ Documentation versioning and history
- ✅ Category and tag-based organization
- ✅ Advanced search and filtering
- ✅ Documentation analytics and usage tracking
- ✅ Collaborative editing and reviews
- ✅ Auto-generated API documentation
- ✅ Multi-language documentation support
- ✅ Documentation templates and workflows
- ✅ Public/private access control
- ✅ TypeScript support

---

## 🗄️ DATABASE SCHEMA

```sql
-- Documentation categories
CREATE TABLE documentation_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES documentation_categories(id),
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Main documentation articles
CREATE TABLE documentation_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  category_id UUID REFERENCES documentation_categories(id),
  content TEXT NOT NULL,
  content_format TEXT NOT NULL CHECK (content_format IN ('markdown', 'html', 'richtext')) DEFAULT 'markdown',
  excerpt TEXT,
  meta_description TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  status TEXT NOT NULL CHECK (status IN ('draft', 'review', 'published', 'archived')) DEFAULT 'draft',
  visibility TEXT NOT NULL CHECK (visibility IN ('public', 'private', 'internal', 'tenant_specific')) DEFAULT 'internal',
  language_code TEXT DEFAULT 'en',
  featured BOOLEAN DEFAULT FALSE,
  view_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMP WITH TIME ZONE,
  author_id UUID NOT NULL REFERENCES users(id),
  reviewer_id UUID REFERENCES users(id),
  published_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation versions for change tracking
CREATE TABLE documentation_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES documentation_articles(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_format TEXT NOT NULL,
  change_summary TEXT,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(article_id, version_number)
);

-- Documentation attachments and media
CREATE TABLE documentation_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES documentation_articles(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_type TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  alt_text TEXT,
  caption TEXT,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation feedback and ratings
CREATE TABLE documentation_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES documentation_articles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  feedback_text TEXT,
  is_helpful BOOLEAN,
  category TEXT CHECK (category IN ('content', 'accuracy', 'clarity', 'completeness', 'suggestion')),
  status TEXT NOT NULL CHECK (status IN ('new', 'reviewed', 'resolved', 'dismissed')) DEFAULT 'new',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation templates
CREATE TABLE documentation_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name TEXT UNIQUE NOT NULL,
  description TEXT,
  template_content TEXT NOT NULL,
  template_format TEXT NOT NULL CHECK (template_format IN ('markdown', 'html', 'richtext')) DEFAULT 'markdown',
  category TEXT NOT NULL CHECK (category IN ('api', 'user_guide', 'admin', 'tutorial', 'reference', 'faq')),
  variables JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation comments and collaborative features
CREATE TABLE documentation_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES documentation_articles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES documentation_comments(id),
  user_id UUID NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  position_start INTEGER,
  position_end INTEGER,
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation analytics
CREATE TABLE documentation_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  article_id UUID REFERENCES documentation_articles(id),
  category_id UUID REFERENCES documentation_categories(id),
  views INTEGER DEFAULT 0,
  unique_visitors INTEGER DEFAULT 0,
  average_time_spent INTERVAL,
  bounce_rate DECIMAL(5,4),
  search_queries TEXT[] DEFAULT ARRAY[]::TEXT[],
  feedback_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date, article_id)
);

-- Documentation search index
CREATE TABLE documentation_search_index (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES documentation_articles(id) ON DELETE CASCADE,
  content_vector tsvector,
  title_vector tsvector,
  tags_vector tsvector,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documentation translations
CREATE TABLE documentation_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_article_id UUID NOT NULL REFERENCES documentation_articles(id),
  language_code TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'review', 'published')) DEFAULT 'draft',
  translator_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(source_article_id, language_code)
);

-- Indexes for performance
CREATE INDEX idx_documentation_articles_category ON documentation_articles(category_id);
CREATE INDEX idx_documentation_articles_status ON documentation_articles(status, visibility);
CREATE INDEX idx_documentation_articles_tags ON documentation_articles USING GIN(tags);
CREATE INDEX idx_documentation_versions_article ON documentation_versions(article_id, version_number);
CREATE INDEX idx_documentation_feedback_article ON documentation_feedback(article_id, status);
CREATE INDEX idx_documentation_analytics_date ON documentation_analytics(date);
CREATE INDEX idx_documentation_search_content ON documentation_search_index USING GIN(content_vector);
CREATE INDEX idx_documentation_search_title ON documentation_search_index USING GIN(title_vector);

-- Full-text search function
CREATE OR REPLACE FUNCTION update_documentation_search_index()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO documentation_search_index (article_id, content_vector, title_vector, tags_vector)
  VALUES (
    NEW.id,
    to_tsvector('english', NEW.content),
    to_tsvector('english', NEW.title),
    to_tsvector('english', array_to_string(NEW.tags, ' '))
  )
  ON CONFLICT (article_id) DO UPDATE SET
    content_vector = to_tsvector('english', NEW.content),
    title_vector = to_tsvector('english', NEW.title),
    tags_vector = to_tsvector('english', array_to_string(NEW.tags, ' ')),
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_documentation_search_trigger
  AFTER INSERT OR UPDATE ON documentation_articles
  FOR EACH ROW EXECUTE FUNCTION update_documentation_search_index();
```

---

## 🎨 UI COMPONENTS

### Documentation Dashboard
```tsx
// components/admin/documentation/DocumentationDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DocumentationEditor } from './DocumentationEditor';
import { DocumentationViewer } from './DocumentationViewer';
import { DocumentationAnalytics } from './DocumentationAnalytics';
import { 
  BookOpen, 
  Plus, 
  Search, 
  Filter,
  Eye,
  Edit,
  Copy,
  Trash2,
  Star,
  MessageSquare,
  BarChart,
  Globe,
  Lock,
  Users,
  Clock
} from 'lucide-react';

interface DocumentationArticle {
  id: string;
  title: string;
  slug: string;
  category_name?: string;
  status: string;
  visibility: string;
  language_code: string;
  featured: boolean;
  view_count: number;
  author_name?: string;
  created_at: string;
  updated_at: string;
  tags: string[];
}

export function DocumentationDashboard() {
  const [articles, setArticles] = useState<DocumentationArticle[]>([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedArticle, setSelectedArticle] = useState<DocumentationArticle | null>(null);
  const [showEditor, setShowEditor] = useState(false);
  const [showViewer, setShowViewer] = useState(false);
  const [filters, setFilters] = useState({
    category: '',
    status: '',
    visibility: '',
    search: '',
    language: 'en'
  });
  const [stats, setStats] = useState({
    total: 0,
    published: 0,
    drafts: 0,
    views: 0
  });

  useEffect(() => {
    loadArticles();
    loadCategories();
    loadStats();
  }, [filters]);

  const loadArticles = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value) params.append(key, value);
      });
      
      const response = await fetch(`/api/admin/documentation/articles?${params}`);
      const data = await response.json();
      setArticles(data.articles || []);
    } catch (error) {
      console.error('Failed to load articles:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    try {
      const response = await fetch('/api/admin/documentation/categories');
      const data = await response.json();
      setCategories(data.categories || []);
    } catch (error) {
      console.error('Failed to load categories:', error);
    }
  };

  const loadStats = async () => {
    try {
      const response = await fetch('/api/admin/documentation/stats');
      const data = await response.json();
      setStats(data.stats || {});
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  };

  const createNewArticle = () => {
    setSelectedArticle(null);
    setShowEditor(true);
  };

  const editArticle = (article: DocumentationArticle) => {
    setSelectedArticle(article);
    setShowEditor(true);
  };

  const viewArticle = (article: DocumentationArticle) => {
    setSelectedArticle(article);
    setShowViewer(true);
  };

  const duplicateArticle = async (article: DocumentationArticle) => {
    try {
      const response = await fetch('/api/admin/documentation/articles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...article,
          title: `${article.title} (Copy)`,
          slug: `${article.slug}-copy-${Date.now()}`,
          status: 'draft',
          id: undefined
        })
      });
      
      if (response.ok) {
        loadArticles();
      }
    } catch (error) {
      console.error('Failed to duplicate article:', error);
    }
  };

  const deleteArticle = async (articleId: string) => {
    if (!confirm('Are you sure you want to delete this article?')) return;
    
    try {
      const response = await fetch(`/api/admin/documentation/articles/${articleId}`, {
        method: 'DELETE'
      });
      
      if (response.ok) {
        loadArticles();
      }
    } catch (error) {
      console.error('Failed to delete article:', error);
    }
  };

  const toggleFeatured = async (articleId: string, featured: boolean) => {
    try {
      const response = await fetch(`/api/admin/documentation/articles/${articleId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ featured: !featured })
      });
      
      if (response.ok) {
        loadArticles();
      }
    } catch (error) {
      console.error('Failed to toggle featured status:', error);
    }
  };

  const getStatusColor = (status: string) => {
    const colors = {
      'draft': 'bg-gray-100 text-gray-800',
      'review': 'bg-yellow-100 text-yellow-800',
      'published': 'bg-green-100 text-green-800',
      'archived': 'bg-red-100 text-red-800'
    };
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getVisibilityIcon = (visibility: string) => {
    const icons = {
      'public': Globe,
      'private': Lock,
      'internal': Users,
      'tenant_specific': Users
    };
    const Icon = icons[visibility as keyof typeof icons] || Lock;
    return <Icon className="w-3 h-3" />;
  };

  if (showEditor) {
    return (
      <DocumentationEditor
        article={selectedArticle}
        categories={categories}
        onClose={() => {
          setShowEditor(false);
          setSelectedArticle(null);
          loadArticles();
        }}
      />
    );
  }

  if (showViewer && selectedArticle) {
    return (
      <DocumentationViewer
        articleId={selectedArticle.id}
        onClose={() => {
          setShowViewer(false);
          setSelectedArticle(null);
        }}
        onEdit={() => {
          setShowViewer(false);
          setShowEditor(true);
        }}
      />
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Documentation</h1>
          <p className="text-gray-600">Manage platform documentation and knowledge base</p>
        </div>
        <Button onClick={createNewArticle}>
          <Plus className="w-4 h-4 mr-2" />
          New Article
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <BookOpen className="h-4 w-4 text-muted-foreground" />
              <div className="ml-2">
                <p className="text-sm font-medium">Total Articles</p>
                <p className="text-2xl font-bold">{stats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Globe className="h-4 w-4 text-green-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Published</p>
                <p className="text-2xl font-bold">{stats.published}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Edit className="h-4 w-4 text-yellow-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Drafts</p>
                <p className="text-2xl font-bold">{stats.drafts}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Eye className="h-4 w-4 text-blue-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Total Views</p>
                <p className="text-2xl font-bold">{stats.views.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="articles" className="space-y-6">
        <TabsList>
          <TabsTrigger value="articles">
            <BookOpen className="w-4 h-4 mr-2" />
            Articles
          </TabsTrigger>
          <TabsTrigger value="analytics">
            <BarChart className="w-4 h-4 mr-2" />
            Analytics
          </TabsTrigger>
        </TabsList>

        <TabsContent value="articles" className="space-y-6">
          {/* Filters */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-4 flex-wrap">
                <div className="relative flex-1 min-w-[200px]">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    placeholder="Search articles..."
                    value={filters.search}
                    onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                    className="pl-10"
                  />
                </div>
                
                <Select value={filters.category} onValueChange={(value) => setFilters({ ...filters, category: value })}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="All Categories" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Categories</SelectItem>
                    {categories.map((category: any) => (
                      <SelectItem key={category.id} value={category.id}>
                        {category.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                
                <Select value={filters.status} onValueChange={(value) => setFilters({ ...filters, status: value })}>
                  <SelectTrigger className="w-32">
                    <SelectValue placeholder="All Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Status</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="review">Review</SelectItem>
                    <SelectItem value="published">Published</SelectItem>
                    <SelectItem value="archived">Archived</SelectItem>
                  </SelectContent>
                </Select>
                
                <Select value={filters.visibility} onValueChange={(value) => setFilters({ ...filters, visibility: value })}>
                  <SelectTrigger className="w-36">
                    <SelectValue placeholder="All Visibility" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Visibility</SelectItem>
                    <SelectItem value="public">Public</SelectItem>
                    <SelectItem value="private">Private</SelectItem>
                    <SelectItem value="internal">Internal</SelectItem>
                    <SelectItem value="tenant_specific">Tenant Specific</SelectItem>
                  </SelectContent>
                </Select>
                
                <Button variant="outline" onClick={loadArticles}>
                  <Filter className="w-4 h-4 mr-2" />
                  Refresh
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Articles List */}
          <div className="space-y-4">
            {loading ? (
              <div className="text-center py-12">Loading articles...</div>
            ) : articles.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                No articles found. Create your first article to get started.
              </div>
            ) : (
              articles.map((article) => (
                <Card key={article.id} className="hover:shadow-md transition-shadow">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <CardTitle className="text-lg">{article.title}</CardTitle>
                          {article.featured && (
                            <Star className="w-4 h-4 text-yellow-500 fill-current" />
                          )}
                        </div>
                        <CardDescription className="mt-1">
                          /{article.slug}
                        </CardDescription>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge 
                          variant="secondary"
                          className={getStatusColor(article.status)}
                        >
                          {article.status}
                        </Badge>
                        <div className="flex items-center text-xs text-gray-500">
                          {getVisibilityIcon(article.visibility)}
                          <span className="ml-1 capitalize">{article.visibility.replace('_', ' ')}</span>
                        </div>
                      </div>
                    </div>
                  </CardHeader>
                  
                  <CardContent className="space-y-3">
                    <div className="flex items-center gap-4 text-sm">
                      {article.category_name && (
                        <span className="text-gray-600">
                          Category: <span className="font-medium">{article.category_name}</span>
                        </span>
                      )}
                      <span className="text-gray-600">
                        Language: <span className="font-medium">{article.language_code.toUpperCase()}</span>
                      </span>
                      <span className="text-gray-600">
                        Views: <span className="font-medium">{article.view_count}</span>
                      </span>
                    </div>
                    
                    {article.tags.length > 0 && (
                      <div className="flex gap-1 flex-wrap">
                        {article.tags.map((tag) => (
                          <Badge key={tag} variant="outline" className="text-xs">
                            {tag}
                          </Badge>
                        ))}
                      </div>
                    )}
                    
                    <div className="flex items-center justify-between pt-2 border-t">
                      <div className="text-xs text-gray-500">
                        <div>Updated: {new Date(article.updated_at).toLocaleDateString()}</div>
                        {article.author_name && (
                          <div>By: {article.author_name}</div>
                        )}
                      </div>
                      
                      <div className="flex items-center gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => viewArticle(article)}
                        >
                          <Eye className="w-3 h-3 mr-1" />
                          View
                        </Button>
                        
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => editArticle(article)}
                        >
                          <Edit className="w-3 h-3 mr-1" />
                          Edit
                        </Button>
                        
                        <div className="flex gap-1">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => toggleFeatured(article.id, article.featured)}
                            className={article.featured ? 'text-yellow-600' : ''}
                          >
                            <Star className={`w-3 h-3 ${article.featured ? 'fill-current' : ''}`} />
                          </Button>
                          
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => duplicateArticle(article)}
                          >
                            <Copy className="w-3 h-3" />
                          </Button>
                          
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => deleteArticle(article.id)}
                          >
                            <Trash2 className="w-3 h-3" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        <TabsContent value="analytics">
          <DocumentationAnalytics />
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### Documentation Editor
```tsx
// components/admin/documentation/DocumentationEditor.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { 
  Save, 
  X, 
  Eye, 
  Code, 
  Type,
  Plus,
  Minus,
  Upload,
  Download,
  Globe,
  Lock
} from 'lucide-react';

interface DocumentationArticle {
  id?: string;
  title: string;
  slug: string;
  category_id: string;
  content: string;
  content_format: string;
  excerpt: string;
  meta_description: string;
  tags: string[];
  status: string;
  visibility: string;
  language_code: string;
  featured: boolean;
}

interface DocumentationEditorProps {
  article: DocumentationArticle | null;
  categories: any[];
  onClose: () => void;
}

export function DocumentationEditor({ article, categories, onClose }: DocumentationEditorProps) {
  const [formData, setFormData] = useState<DocumentationArticle>({
    title: '',
    slug: '',
    category_id: '',
    content: '',
    content_format: 'markdown',
    excerpt: '',
    meta_description: '',
    tags: [],
    status: 'draft',
    visibility: 'internal',
    language_code: 'en',
    featured: false
  });
  
  const [saving, setSaving] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);
  const [newTag, setNewTag] = useState('');

  useEffect(() => {
    if (article) {
      setFormData({
        ...article,
        tags: article.tags || []
      });
    }
  }, [article]);

  const handleSave = async (status?: string) => {
    setSaving(true);
    try {
      const saveData = {
        ...formData,
        status: status || formData.status
      };
      
      const url = article 
        ? `/api/admin/documentation/articles/${article.id}`
        : '/api/admin/documentation/articles';
      
      const method = article ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(saveData)
      });
      
      if (response.ok) {
        onClose();
      }
    } catch (error) {
      console.error('Failed to save article:', error);
    } finally {
      setSaving(false);
    }
  };

  const addTag = () => {
    if (newTag && !formData.tags.includes(newTag)) {
      setFormData({
        ...formData,
        tags: [...formData.tags, newTag]
      });
      setNewTag('');
    }
  };

  const removeTag = (tag: string) => {
    setFormData({
      ...formData,
      tags: formData.tags.filter(t => t !== tag)
    });
  };

  const generateSlug = (title: string) => {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  };

  const handleTitleChange = (title: string) => {
    setFormData({
      ...formData,
      title,
      slug: !article ? generateSlug(title) : formData.slug
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">
            {article ? 'Edit Article' : 'Create Article'}
          </h1>
          <p className="text-gray-600">
            {article ? `Editing: ${article.title}` : 'Create a new documentation article'}
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={onClose}>
            <X className="w-4 h-4 mr-2" />
            Cancel
          </Button>
          <Button 
            variant="outline" 
            onClick={() => handleSave()}
            disabled={saving}
          >
            <Save className="w-4 h-4 mr-2" />
            Save Draft
          </Button>
          <Button 
            onClick={() => handleSave('published')}
            disabled={saving || !formData.title || !formData.content}
          >
            <Globe className="w-4 h-4 mr-2" />
            Publish
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-3 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Article Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Title</label>
                <Input
                  value={formData.title}
                  onChange={(e) => handleTitleChange(e.target.value)}
                  placeholder="Enter article title"
                />
              </div>

              <div>
                <label className="text-sm font-medium">URL Slug</label>
                <Input
                  value={formData.slug}
                  onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                  placeholder="article-url-slug"
                />
              </div>

              <div>
                <label className="text-sm font-medium">Excerpt</label>
                <Textarea
                  value={formData.excerpt}
                  onChange={(e) => setFormData({ ...formData, excerpt: e.target.value })}
                  placeholder="Brief description of the article"
                  className="h-20"
                />
              </div>

              <div>
                <label className="text-sm font-medium">Meta Description</label>
                <Textarea
                  value={formData.meta_description}
                  onChange={(e) => setFormData({ ...formData, meta_description: e.target.value })}
                  placeholder="SEO meta description"
                  className="h-16"
                />
              </div>
            </CardContent>
          </Card>

          {/* Content Editor */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Content</CardTitle>
                <div className="flex gap-2">
                  <Select 
                    value={formData.content_format}
                    onValueChange={(value) => setFormData({ ...formData, content_format: value })}
                  >
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="markdown">Markdown</SelectItem>
                      <SelectItem value="html">HTML</SelectItem>
                      <SelectItem value="richtext">Rich Text</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => setPreviewMode(!previewMode)}
                  >
                    <Eye className="w-4 h-4 mr-2" />
                    {previewMode ? 'Edit' : 'Preview'}
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {previewMode ? (
                <div className="prose max-w-none min-h-[500px] p-4 border rounded">
                  {/* Preview content would be rendered here */}
                  <div dangerouslySetInnerHTML={{ __html: formData.content }} />
                </div>
              ) : (
                <Textarea
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  placeholder={`Enter content in ${formData.content_format} format...`}
                  className="min-h-[500px] font-mono text-sm"
                />
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Publishing Options */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Publishing</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Status</label>
                <Select 
                  value={formData.status}
                  onValueChange={(value) => setFormData({ ...formData, status: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="review">Review</SelectItem>
                    <SelectItem value="published">Published</SelectItem>
                    <SelectItem value="archived">Archived</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium">Visibility</label>
                <Select 
                  value={formData.visibility}
                  onValueChange={(value) => setFormData({ ...formData, visibility: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="public">
                      <div className="flex items-center">
                        <Globe className="w-4 h-4 mr-2" />
                        Public
                      </div>
                    </SelectItem>
                    <SelectItem value="internal">
                      <div className="flex items-center">
                        <Lock className="w-4 h-4 mr-2" />
                        Internal
                      </div>
                    </SelectItem>
                    <SelectItem value="private">Private</SelectItem>
                    <SelectItem value="tenant_specific">Tenant Specific</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium">Language</label>
                <Select 
                  value={formData.language_code}
                  onValueChange={(value) => setFormData({ ...formData, language_code: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="en">English</SelectItem>
                    <SelectItem value="es">Spanish</SelectItem>
                    <SelectItem value="fr">French</SelectItem>
                    <SelectItem value="de">German</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={formData.featured}
                  onChange={(e) => setFormData({ ...formData, featured: e.target.checked })}
                  className="rounded"
                />
                <span className="text-sm font-medium">Featured Article</span>
              </label>
            </CardContent>
          </Card>

          {/* Categories and Tags */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Organization</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Category</label>
                <Select 
                  value={formData.category_id}
                  onValueChange={(value) => setFormData({ ...formData, category_id: value })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select category" />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map((category) => (
                      <SelectItem key={category.id} value={category.id}>
                        {category.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium">Tags</label>
                <div className="flex gap-2 mb-2">
                  <Input
                    value={newTag}
                    onChange={(e) => setNewTag(e.target.value)}
                    placeholder="Add tag"
                    onKeyPress={(e) => e.key === 'Enter' && addTag()}
                  />
                  <Button size="sm" onClick={addTag}>
                    <Plus className="w-4 h-4" />
                  </Button>
                </div>
                <div className="flex gap-1 flex-wrap">
                  {formData.tags.map((tag) => (
                    <Badge key={tag} variant="secondary" className="text-xs">
                      {tag}
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => removeTag(tag)}
                        className="ml-1 h-auto p-0"
                      >
                        <X className="w-3 h-3" />
                      </Button>
                    </Badge>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" className="w-full" size="sm">
                <Upload className="w-4 h-4 mr-2" />
                Upload Image
              </Button>
              <Button variant="outline" className="w-full" size="sm">
                <Download className="w-4 h-4 mr-2" />
                Export Article
              </Button>
              <Button variant="outline" className="w-full" size="sm">
                <Code className="w-4 h-4 mr-2" />
                Insert Code Block
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
```

---

## 🔧 API ROUTES

### Documentation Articles API
```typescript
// app/api/admin/documentation/articles/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { requireSuperAdmin } from '@/lib/auth/require-roles';

export async function GET(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();

    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const status = searchParams.get('status');
    const visibility = searchParams.get('visibility');
    const search = searchParams.get('search');
    const language = searchParams.get('language') || 'en';

    let query = supabase
      .from('documentation_articles')
      .select(`
        *,
        documentation_categories(name),
        users(first_name, last_name)
      `)
      .eq('language_code', language)
      .order('updated_at', { ascending: false });

    if (category) {
      query = query.eq('category_id', category);
    }

    if (status) {
      query = query.eq('status', status);
    }

    if (visibility) {
      query = query.eq('visibility', visibility);
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
    }

    const { data: articles, error } = await query;

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch articles' }, { status: 500 });
    }

    // Format response
    const formattedArticles = articles?.map(article => ({
      ...article,
      category_name: article.documentation_categories?.name,
      author_name: article.users ? 
        `${article.users.first_name} ${article.users.last_name}` : 
        null
    }));

    return NextResponse.json({ articles: formattedArticles || [] });
  } catch (error) {
    console.error('Failed to fetch documentation articles:', error);
    return NextResponse.json(
      { error: 'Failed to fetch articles' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireSuperAdmin();
    const supabase = createClient();
    const user = await supabase.auth.getUser();
    const body = await request.json();

    // Check if slug is unique
    const { data: existing } = await supabase
      .from('documentation_articles')
      .select('id')
      .eq('slug', body.slug)
      .single();

    if (existing) {
      return NextResponse.json(
        { error: 'Article slug already exists' },
        { status: 400 }
      );
    }

    const { data: article, error } = await supabase
      .from('documentation_articles')
      .insert({
        ...body,
        author_id: user.data.user?.id
      })
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to create article' }, { status: 500 });
    }

    // Create initial version
    await supabase
      .from('documentation_versions')
      .insert({
        article_id: article.id,
        version_number: 1,
        title: article.title,
        content: article.content,
        content_format: article.content_format,
        change_summary: 'Initial version',
        created_by: user.data.user?.id
      });

    return NextResponse.json(article, { status: 201 });
  } catch (error) {
    console.error('Failed to create documentation article:', error);
    return NextResponse.json(
      { error: 'Failed to create article' },
      { status: 500 }
    );
  }
}
```

### Documentation Search API
```typescript
// app/api/admin/documentation/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  try {
    const supabase = createClient();
    const { searchParams } = new URL(request.url);
    const query = searchParams.get('q');

    if (!query) {
      return NextResponse.json({ results: [] });
    }

    const { data: results, error } = await supabase
      .from('documentation_articles')
      .select(`
        id,
        title,
        slug,
        excerpt,
        documentation_categories(name)
      `)
      .or(`title.ilike.%${query}%,content.ilike.%${query}%,tags.cs.{${query}}`)
      .eq('status', 'published')
      .limit(10);

    if (error) {
      console.error('Search error:', error);
      return NextResponse.json({ error: 'Search failed' }, { status: 500 });
    }

    return NextResponse.json({ results: results || [] });
  } catch (error) {
    console.error('Documentation search failed:', error);
    return NextResponse.json(
      { error: 'Search failed' },
      { status: 500 }
    );
  }
}
```

---

## ⚙️ DOCUMENTATION UTILITIES

### Documentation Generator
```typescript
// lib/documentation/generator.ts
import { createClient } from '@/lib/supabase/server';

export class DocumentationGenerator {
  private supabase = createClient();

  async generateAPIDocumentation() {
    // Auto-generate API documentation from code
    const apiRoutes = await this.scanAPIRoutes();
    
    for (const route of apiRoutes) {
      await this.createOrUpdateAPIDoc(route);
    }
  }

  private async scanAPIRoutes() {
    // Scan API routes and extract documentation
    // This would integrate with your API route structure
    return [];
  }

  private async createOrUpdateAPIDoc(route: any) {
    const { data: existing } = await this.supabase
      .from('documentation_articles')
      .select('id')
      .eq('slug', `api-${route.path.replace(/\//g, '-')}`)
      .single();

    const content = this.generateAPIContent(route);

    if (existing) {
      await this.supabase
        .from('documentation_articles')
        .update({
          content,
          updated_at: new Date().toISOString()
        })
        .eq('id', existing.id);
    } else {
      await this.supabase
        .from('documentation_articles')
        .insert({
          title: `API: ${route.path}`,
          slug: `api-${route.path.replace(/\//g, '-')}`,
          content,
          content_format: 'markdown',
          status: 'published',
          visibility: 'internal',
          category_id: await this.getAPICategory()
        });
    }
  }

  private generateAPIContent(route: any) {
    return `
# ${route.method.toUpperCase()} ${route.path}

${route.description || 'API endpoint documentation'}

## Parameters

${route.parameters?.map((param: any) => `- **${param.name}** (${param.type}): ${param.description}`).join('\n') || 'No parameters'}

## Response

\`\`\`json
${JSON.stringify(route.responseExample || {}, null, 2)}
\`\`\`

## Example

\`\`\`bash
curl -X ${route.method.toUpperCase()} "${route.path}"
\`\`\`
`;
  }

  private async getAPICategory() {
    const { data: category } = await this.supabase
      .from('documentation_categories')
      .select('id')
      .eq('name', 'API Reference')
      .single();

    return category?.id;
  }
}
```

---

## 📋 TESTING REQUIREMENTS

### Documentation Tests
```typescript
// __tests__/admin/documentation/DocumentationDashboard.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { DocumentationDashboard } from '@/components/admin/documentation/DocumentationDashboard';

const mockArticles = [
  {
    id: '1',
    title: 'Getting Started Guide',
    slug: 'getting-started-guide',
    category_name: 'User Guides',
    status: 'published',
    visibility: 'public',
    language_code: 'en',
    featured: true,
    view_count: 150,
    author_name: 'John Doe',
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
    tags: ['guide', 'beginner']
  }
];

describe('DocumentationDashboard', () => {
  beforeEach(() => {
    global.fetch = jest.fn()
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ articles: mockArticles })
      })
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ categories: [] })
      })
      .mockResolvedValueOnce({
        json: () => Promise.resolve({ 
          stats: { total: 10, published: 8, drafts: 2, views: 1250 }
        })
      });
  });

  it('renders documentation dashboard', async () => {
    render(<DocumentationDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Documentation')).toBeInTheDocument();
    });
  });

  it('displays documentation stats', async () => {
    render(<DocumentationDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Total Articles')).toBeInTheDocument();
      expect(screen.getByText('10')).toBeInTheDocument();
    });
  });

  it('displays articles list', async () => {
    render(<DocumentationDashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('Getting Started Guide')).toBeInTheDocument();
      expect(screen.getByText('Views: 150')).toBeInTheDocument();
    });
  });

  it('filters articles by status', async () => {
    render(<DocumentationDashboard />);
    
    await waitFor(() => {
      const statusFilter = screen.getByDisplayValue('All Status');
      fireEvent.click(statusFilter);
      
      const publishedOption = screen.getByText('Published');
      fireEvent.click(publishedOption);
    });
    
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('status=published')
    );
  });
});
```

---

## 🔐 PERMISSIONS & ROLES

### Required Permissions
- **Super Admin**: Full access to all documentation features
- **Documentation Manager**: Create, edit, and manage all documentation
- **Content Writer**: Create and edit assigned documentation
- **Reviewer**: Review and approve documentation

### Role-based Access Control
```sql
-- Documentation management permissions
INSERT INTO role_permissions (role_name, permission) VALUES
('super_admin', 'documentation:manage_all'),
('super_admin', 'documentation:create_articles'),
('super_admin', 'documentation:edit_system_docs'),
('super_admin', 'documentation:view_analytics'),
('documentation_manager', 'documentation:manage_content'),
('documentation_manager', 'documentation:create_articles'),
('documentation_manager', 'documentation:view_analytics'),
('content_writer', 'documentation:create_articles'),
('content_writer', 'documentation:edit_own'),
('reviewer', 'documentation:review_articles');
```

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Last Updated**: January 5, 2025  
**Version**: 1.0.0  
**Priority**: MEDIUM