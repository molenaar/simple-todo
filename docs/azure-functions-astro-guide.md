# Azure Functions + Astro Integration Guide

> Based on [Elio Struyf's excellent article](https://www.eliostruyf.com/integrating-azure-functions-astro-site/) on integrating Azure Functions with Astro sites.

## Overview

This guide shows how to integrate Azure Functions with your Astro site using the Azure Static Web Apps CLI for seamless development and deployment. The key insight is using the SWA CLI to proxy both your Astro site and Azure Functions during development, eliminating CORS issues and simplifying the build process.

## Project Structure

```
course-platform/
├── app/                    # Astro site
│   ├── src/
│   │   ├── pages/
│   │   │   ├── courses/
│   │   │   │   └── [courseid].astro
│   │   │   └── index.astro
│   │   └── components/
│   │       └── CourseLoader.tsx
│   ├── package.json
│   └── astro.config.mjs
├── api/                    # Azure Functions
│   ├── src/
│   │   └── functions/
│   │       └── courses.ts
│   ├── package.json
│   └── host.json
├── swa-cli.config.json     # SWA configuration
├── package.json            # Root package.json
└── .github/workflows/
    └── deploy.yml
```

## Configuration Files

### SWA CLI Configuration

```json
// swa-cli.config.json
{
  "$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "course-platform": {
      "appLocation": "./app",
      "outputLocation": "dist",
      "appDevserverUrl": "http://localhost:4321",
      "apiLocation": "./api",
      "apiLanguage": "node",
      "apiVersion": "18",
      "apiDevserverUrl": "http://localhost:7071"
    }
  }
}
```

### Root Package.json

```json
// package.json (root)
{
  "name": "course-platform",
  "scripts": {
    "build": "npm run build:app && npm run build:api",
    "build:app": "cd app && npm run build",
    "build:api": "cd api && npm run build",
    "dev": "npm-run-all --parallel dev:*",
    "dev:swa": "swa start",
    "dev:app": "cd app && npm run dev",
    "dev:api": "cd api && npm run start",
    "deploy": "swa deploy",
    "install:all": "npm ci && cd app && npm ci && cd ../api && npm ci"
  },
  "devDependencies": {
    "@azure/static-web-apps-cli": "^2.0.1",
    "npm-run-all": "^4.1.5"
  }
}
```

### Azure Functions Setup

```bash
# Initialize Azure Functions project
func init api --worker-runtime typescript --model V4

# Navigate to API folder
cd api

# Create HTTP trigger function
func new --template "HTTP trigger" --name courses
```

## Dynamic Course Page Implementation

### Astro Course Page

```typescript
// app/src/pages/courses/[courseid].astro
---
export async function getStaticPaths() {
  // During development with SWA CLI, API is available!
  // In production build, this might still return empty, but that's OK
  try {
    // This will work in development with SWA CLI
    const response = await fetch('http://localhost:7071/api/courses');
    const courses = await response.json();
    
    return courses.map((course: any) => ({
      params: { courseid: course.id },
      props: { course }
    }));
  } catch (error) {
    console.log('API not available during build, using client-side loading');
    return [];
  }
}

const { courseid } = Astro.params;
const { course } = Astro.props;
---

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{course?.title || `Course ${courseid}`}</title>
  <meta name="description" content={course?.description || "Loading course content..."}>
</head>
<body>
  <div class="container mx-auto px-4 py-8">
    <!-- Static content if available from build -->
    {course ? (
      <div>
        <h1 class="text-4xl font-bold mb-4">{course.title}</h1>
        <div class="prose prose-lg" set:html={course.contentHtml}></div>
      </div>
    ) : (
      <!-- Fallback to dynamic loading -->
      <div id="course-container">
        <div class="animate-pulse">
          <div class="h-8 bg-gray-200 rounded w-3/4 mb-4"></div>
          <div class="h-4 bg-gray-200 rounded w-1/2 mb-8"></div>
          <div class="space-y-4">
            <div class="h-4 bg-gray-200 rounded w-full"></div>
            <div class="h-4 bg-gray-200 rounded w-5/6"></div>
          </div>
        </div>
      </div>
    )}
  </div>

  <!-- Only load dynamic content if static content wasn't available -->
  {!course && (
    <script define:vars={{ courseid }}>
      import { CourseLoader } from '../../components/CourseLoader';
      
      document.addEventListener('DOMContentLoaded', async () => {
        const loader = new CourseLoader(courseid);
        await loader.loadCourse();
      });
    </script>
  )}
</body>
</html>
```

### React Course Loader Component

```tsx
// app/src/components/CourseLoader.tsx
import { useState, useEffect } from 'react';

interface CourseData {
  courseId: string;
  title: string;
  description?: string;
  content: string;
  lastModified: string;
}

// API host detection (following Elio's pattern)
const apiHost = import.meta.env.DEV 
  ? "http://localhost:4280"  // SWA CLI proxy
  : window.location.origin;   // Production SWA

interface CourseLoaderProps {
  courseid: string;
}

export const CourseLoader: React.FC<CourseLoaderProps> = ({ courseid }) => {
  const [course, setCourse] = useState<CourseData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCourse = async (): Promise<CourseData> => {
    const apiUrl = `${apiHost}/api/courses/${courseid}`;
    
    try {
      const response = await fetch(apiUrl);
      
      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Course not found');
        }
        throw new Error(`Failed to load course: ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('Course fetch error:', error);
      console.log('Attempted URL:', apiUrl);
      throw error;
    }
  };

  useEffect(() => {
    const loadCourse = async () => {
      try {
        const courseData = await fetchCourse();
        setCourse(courseData);
        
        // Update page title and meta
        document.title = `${courseData.title} - Course Platform`;
        const metaDesc = document.querySelector('meta[name="description"]');
        if (metaDesc) {
          metaDesc.content = courseData.description || courseData.title;
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    loadCourse();
  }, [courseid]);

  const processMarkdown = (markdown: string): string => {
    return markdown
      .replace(/^# (.*$)/gim, '<h1 class="text-3xl font-bold mb-6 text-gray-900">$1</h1>')
      .replace(/^## (.*$)/gim, '<h2 class="text-2xl font-semibold mb-4 text-gray-800">$1</h2>')
      .replace(/^### (.*$)/gim, '<h3 class="text-xl font-medium mb-3 text-gray-700">$1</h3>')
      .replace(/\*\*(.*?)\*\*/gim, '<strong class="font-semibold">$1</strong>')
      .replace(/\*(.*?)\*/gim, '<em class="italic">$1</em>')
      .replace(/`(.*?)`/gim, '<code class="bg-gray-100 px-1 py-0.5 rounded text-sm font-mono">$1</code>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2" class="text-blue-600 underline hover:text-blue-800">$1</a>')
      .split('\n\n')
      .map(paragraph => paragraph.trim())
      .filter(paragraph => paragraph.length > 0)
      .map(paragraph => `<p class="mb-4 leading-relaxed">${paragraph.replace(/\n/g, '<br>')}</p>`)
      .join('');
  };

  if (loading) {
    return (
      <div className="animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-3/4 mb-4"></div>
        <div className="h-4 bg-gray-200 rounded w-1/2 mb-8"></div>
        <div className="space-y-4">
          <div className="h-4 bg-gray-200 rounded w-full"></div>
          <div className="h-4 bg-gray-200 rounded w-5/6"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <h2 className="text-xl font-semibold text-red-800 mb-2">Course Not Found</h2>
        <p className="text-red-600 mb-4">{error}</p>
        <a href="/courses" className="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700">
          ← Back to Courses
        </a>
      </div>
    );
  }

  if (!course) return null;

  return (
    <div>
      <header className="mb-8">
        <h1 className="text-4xl font-bold text-gray-900 mb-2">{course.title}</h1>
        {course.description && (
          <p className="text-gray-600 text-lg">{course.description}</p>
        )}
        <div className="flex items-center space-x-4 mt-4 text-sm text-gray-500">
          <span>Course ID: {course.courseId}</span>
          <span>Last Updated: {new Date(course.lastModified).toLocaleDateString()}</span>
        </div>
      </header>
      
      <main 
        className="prose prose-lg max-w-none"
        dangerouslySetInnerHTML={{ __html: processMarkdown(course.content) }}
      />
    </div>
  );
};
```

## Azure Functions Implementation

### Course API Function

```typescript
// api/src/functions/courses.ts
import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { BlobServiceClient } from "@azure/storage-blob";

// Initialize Azure Storage client
const blobServiceClient = BlobServiceClient.fromConnectionString(
  process.env.AZURE_STORAGE_CONNECTION_STRING || ""
);

interface CourseData {
  courseId: string;
  title: string;
  description?: string;
  content: string;
  lastModified: string;
}

export async function getCourse(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  const courseid = request.params.courseid;

  if (!courseid) {
    return {
      status: 400,
      jsonBody: { error: "Course ID is required" }
    };
  }

  try {
    context.log(`Fetching course: ${courseid}`);

    // Get the blob container
    const containerClient = blobServiceClient.getContainerClient("course-content");
    const blobClient = containerClient.getBlobClient(`${courseid}.md`);

    // Check if blob exists
    if (!(await blobClient.exists())) {
      context.warn(`Course not found: ${courseid}`);
      return {
        status: 404,
        jsonBody: { error: "Course not found" }
      };
    }

    // Download the markdown content
    const response = await blobClient.downloadContent();
    const markdownContent = response.content?.toString() || "";

    // Get blob properties for metadata
    const properties = await blobClient.getProperties();

    const courseData: CourseData = {
      courseId: courseid,
      title: extractTitleFromMarkdown(markdownContent),
      description: extractDescriptionFromMarkdown(markdownContent),
      content: markdownContent,
      lastModified: properties.lastModified?.toISOString() || new Date().toISOString()
    };

    return {
      status: 200,
      jsonBody: courseData,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=300" // 5 minute cache
      }
    };
  } catch (error) {
    context.error(`Error fetching course ${courseid}:`, error);
    return {
      status: 500,
      jsonBody: { error: "Internal server error" }
    };
  }
}

export async function listCourses(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  try {
    context.log("Listing all courses");

    const containerClient = blobServiceClient.getContainerClient("course-content");
    const courses: { id: string; title: string }[] = [];

    // List all .md files in the container
    for await (const blob of containerClient.listBlobsFlat()) {
      if (blob.name.endsWith(".md")) {
        const courseId = blob.name.replace(".md", "");
        
        // Optionally fetch title from blob metadata or content
        // For performance, you might store titles in blob metadata
        courses.push({
          id: courseId,
          title: courseId.replace(/-/g, " ").replace(/\b\w/g, l => l.toUpperCase())
        });
      }
    }

    return {
      status: 200,
      jsonBody: courses,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=600" // 10 minute cache
      }
    };
  } catch (error) {
    context.error("Error listing courses:", error);
    return {
      status: 500,
      jsonBody: { error: "Internal server error" }
    };
  }
}

// Helper functions
function extractTitleFromMarkdown(markdown: string): string {
  const lines = markdown.split('\n');
  const titleLine = lines.find(line => line.startsWith("# "));
  return titleLine?.substring(2).trim() || "Untitled Course";
}

function extractDescriptionFromMarkdown(markdown: string): string {
  const lines = markdown.split('\n');
  return lines.slice(1).find(line => line.trim() && !line.startsWith("#"))?.trim() || "";
}

// Register HTTP triggers
app.http("courses-get", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: getCourse,
  route: "courses/{courseid}"
});

app.http("courses-list", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: listCourses,
  route: "courses"
});
```

## Deployment Configuration

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy Course Platform

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    name: Build and Deploy
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"
          cache: "npm"

      - name: Install dependencies
        run: |
          npm ci
          cd app && npm ci
          cd ../api && npm ci

      - name: Build
        run: npm run build

      - name: Clean API dependencies (production only)
        run: cd api && npm ci --omit=dev

      - name: Deploy to Azure Static Web Apps
        run: npx @azure/static-web-apps-cli deploy -d ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }} --env production
```

### Azure Static Web Apps Configuration

```json
// staticwebapp.config.json
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    }
  ],
  "navigationFallback": {
    "rewrite": "/404.html",
    "exclude": ["/api/*", "*.{css,scss,js,png,jpg,ico,svg,woff,woff2}"]
  },
  "mimeTypes": {
    ".json": "application/json"
  }
}
```

## Local Development Commands

```bash
# Install all dependencies
npm run install:all

# Start development (both app and API)
npm run dev

# Build for production
npm run build

# Deploy to Azure
npm run deploy
```

## Key Benefits

1. **🎯 Unified Development**: Both API and site run together locally through SWA CLI proxy
2. **🚀 Simplified Deployment**: Single command deploys everything to Azure Static Web Apps
3. **🔄 No CORS Issues**: API and site share the same origin during development and production
4. **⚡ Better DX**: Hot reload works for both Azure Functions and Astro
5. **🏗️ Build-Time API**: API is available during `getStaticPaths` in development
6. **📈 Hybrid Rendering**: Static when possible, dynamic when needed
7. **🛡️ Type Safety**: Full TypeScript support across the stack

## Environment Variables

Set these in your Azure Static Web App configuration:

```
AZURE_STORAGE_CONNECTION_STRING=your_storage_connection_string
```

## Notes

- The SWA CLI proxy runs on `http://localhost:4280` by default
- Azure Functions run on `http://localhost:7071` by default
- Astro dev server runs on `http://localhost:4321` by default
- All requests are proxied through the SWA CLI, eliminating CORS issues
- In production, all services run under the same Azure Static Web Apps domain

## Credit

This implementation is based on [Elio Struyf's excellent article](https://www.eliostruyf.com/integrating-azure-functions-astro-site/) on integrating Azure Functions with Astro sites. The approach has been adapted for a course content management system with markdown files stored in Azure Storage.