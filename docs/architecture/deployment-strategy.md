# Deployment Strategy

The Simple To-Do application deploys to Azure Static Web Apps using GitHub Actions, following Elio Struyf's proven methodologies for efficient CI/CD pipelines and optimal Azure SWA configuration. This strategy ensures reliable deployments while maintaining cost efficiency on the free tier.

### Azure Static Web Apps Configuration

The application leverages Azure Static Web Apps' native integration with Astro and GitHub Actions:

```json
// staticwebapp.config.json - Azure SWA configuration
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    },
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*.{png,jpg,gif,webp}", "/css/*", "/js/*", "/api/*"]
  },
  "mimeTypes": {
    ".json": "application/json",
    ".webmanifest": "application/manifest+json"
  },
  "globalHeaders": {
    "Cache-Control": "public, max-age=31536000, immutable",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()"
  },
  "responseOverrides": {
    "400": {
      "rewrite": "/400.html",
      "statusCode": 400
    },
    "401": {
      "rewrite": "/401.html", 
      "statusCode": 401
    },
    "403": {
      "rewrite": "/403.html",
      "statusCode": 403
    },
    "404": {
      "rewrite": "/404.html",
      "statusCode": 404
    }
  },
  "platform": {
    "apiRuntime": "node:20"
  },
  "forwardingGateway": {
    "allowedForwardedHosts": [],
    "requiredHeaders": {}
  }
}
```

### GitHub Actions CI/CD Pipeline

The deployment pipeline follows best practices for Astro builds and Azure Static Web Apps integration:

```yaml
# .github/workflows/azure-static-web-apps.yml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
          lfs: false

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: './app/package-lock.json'

      - name: Install dependencies
        run: |
          cd app
          npm ci --prefer-offline --no-audit

      - name: Run type checking
        run: |
          cd app
          npm run type-check

      - name: Run linting
        run: |
          cd app
          npm run lint

      - name: Run tests
        run: |
          cd app
          npm run test

      - name: Build application
        run: |
          cd app
          npm run build
        env:
          # Ensure build optimizations
          NODE_ENV: production
          # Future API endpoint (empty for MVP)
          PUBLIC_API_ENDPOINT: ""

      - name: Deploy to Azure Static Web Apps
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/app"
          app_build_command: "npm run build"
          output_location: "dist"
          skip_app_build: true # We already built above

      - name: Upload build artifacts (on failure)
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: |
            app/dist/
            app/.astro/
          retention-days: 5

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: "close"
```

### Environment-Specific Configuration

The application supports multiple environments with appropriate configuration:

```typescript
// app/src/config/environment.ts - Environment configuration
interface EnvironmentConfig {
  NODE_ENV: 'development' | 'production' | 'test';
  API_ENDPOINT: string;
  STORAGE_PREFIX: string;
  VERSION: string;
  BUILD_TIME: string;
  ANALYTICS_ID?: string;
  SENTRY_DSN?: string;
}

// Runtime environment detection
const getEnvironmentConfig = (): EnvironmentConfig => {
  // Astro environment variables (import.meta.env)
  const env = import.meta.env;
  
  return {
    NODE_ENV: env.MODE as 'development' | 'production' | 'test',
    API_ENDPOINT: env.PUBLIC_API_ENDPOINT || '',
    STORAGE_PREFIX: env.PUBLIC_STORAGE_PREFIX || 'simple-todo',
    VERSION: env.PUBLIC_VERSION || '1.0.0',
    BUILD_TIME: env.PUBLIC_BUILD_TIME || new Date().toISOString(),
    ANALYTICS_ID: env.PUBLIC_ANALYTICS_ID,
    SENTRY_DSN: env.PUBLIC_SENTRY_DSN
  };
};

export const config = getEnvironmentConfig();

// Environment-specific behavior
export const isDevelopment = config.NODE_ENV === 'development';
export const isProduction = config.NODE_ENV === 'production';
export const isTest = config.NODE_ENV === 'test';

// Feature flags for environment-specific functionality
export const features = {
  enableAnalytics: isProduction && !!config.ANALYTICS_ID,
  enableErrorReporting: isProduction && !!config.SENTRY_DSN,
  enableDebugMode: isDevelopment,
  enableServiceWorker: isProduction,
  enableDetailedLogging: isDevelopment || isTest
};
```

### Performance Optimization Strategy

The build process incorporates comprehensive optimization for Azure Static Web Apps:

```javascript
// astro.config.mjs - Production-optimized Astro configuration
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://simple-todo.azurestaticapps.net', // Will be updated with actual domain
  
  // Output configuration for static deployment
  output: 'static',
  
  // Build optimizations
  build: {
    // Inline small assets for fewer requests
    assetsInlineLimit: 4096,
    
    // Enable asset splitting for optimal caching
    rollupOptions: {
      output: {
        // Split vendor code for better caching
        manualChunks: {
          vendor: ['uuid'],
          utils: ['./src/scripts/services/ValidationService.ts', './src/scripts/services/StorageManager.ts']
        },
        
        // Optimize asset naming for caching
        assetFileNames: (assetInfo) => {
          const info = assetInfo.name.split('.');
          let extType = info[info.length - 1];
          
          if (/png|jpe?g|svg|gif|tiff|bmp|ico/i.test(extType)) {
            extType = 'images';
          } else if (/woff2?|eot|ttf|otf/i.test(extType)) {
            extType = 'fonts';
          }
          
          return `assets/${extType}/[name].[hash][extname]`;
        },
        
        chunkFileNames: 'assets/js/[name].[hash].js',
        entryFileNames: 'assets/js/[name].[hash].js'
      }
    }
  },
  
  // Development server configuration
  server: {
    port: 4321,
    host: true // Allow network access for testing
  },
  
  // Preview server (for production builds)
  preview: {
    port: 4322,
    host: true
  },
  
  // Integrations
  integrations: [
    tailwind({
      // Apply base styles automatically
      applyBaseStyles: false // We'll handle this manually in global.css
    })
  ],
  
  // Vite-specific optimizations
  vite: {
    build: {
      // Enable CSS code splitting
      cssCodeSplit: true,
      
      // Optimize bundle size
      reportCompressedSize: true,
      
      // Target modern browsers for smaller bundles
      target: 'es2022'
    },
    
    // Dependency optimization
    optimizeDeps: {
      include: ['uuid'],
      exclude: []
    }
  }
});
```

### Monitoring and Analytics Setup

Integration with Azure Application Insights and performance monitoring:

```typescript
// src/scripts/services/AnalyticsService.ts - Privacy-conscious analytics
export class AnalyticsService {
  private static initialized = false;
  private static analyticsId?: string;
  
  static initialize(config: { analyticsId?: string; enableAnalytics: boolean }): void {
    if (!config.enableAnalytics || !config.analyticsId || this.initialized) {
      return;
    }
    
    this.analyticsId = config.analyticsId;
    this.loadApplicationInsights();
    this.initialized = true;
  }
  
  // Track key user interactions (privacy-conscious)
  static trackEvent(eventName: string, properties?: Record<string, any>): void {
    if (!this.initialized || !window.appInsights) {
      return;
    }
    
    // Only track functional events, not personal data
    const sanitizedProperties = this.sanitizeProperties(properties);
    
    window.appInsights.trackEvent({
      name: eventName,
      properties: sanitizedProperties
    });
  }
  
  // Track performance metrics
  static trackPerformance(metricName: string, value: number): void {
    if (!this.initialized || !window.appInsights) {
      return;
    }
    
    window.appInsights.trackMetric({
      name: metricName,
      average: value
    });
  }
  
  // Track application errors (excluding sensitive data)
  static trackError(error: Error, properties?: Record<string, any>): void {
    if (!this.initialized || !window.appInsights) {
      console.error('Application Error:', error);
      return;
    }
    
    window.appInsights.trackException({
      exception: error,
      properties: this.sanitizeProperties(properties)
    });
  }
  
  private static loadApplicationInsights(): void {
    // Dynamically load Application Insights
    const script = document.createElement('script');
    script.src = 'https://js.monitor.azure.com/scripts/b/ai.2.min.js';
    script.onload = () => this.configureApplicationInsights();
    document.head.appendChild(script);
  }
  
  private static configureApplicationInsights(): void {
    if (!this.analyticsId) return;
    
    const aiConfig = {
      connectionString: `InstrumentationKey=${this.analyticsId}`,
      
      // Privacy-first configuration
      enableAutoRouteTracking: false, // We'll track manually
      disableFetchTracking: true, // Avoid tracking API calls
      enableCorsCorrelation: false,
      
      // Performance configuration
      samplingPercentage: 100,
      maxBatchInterval: 15000,
      maxBatchSizeInBytes: 25000
    };
    
    window.appInsights = new ApplicationInsights({ config: aiConfig });
    window.appInsights.loadAppInsights();
  }
  
  private static sanitizeProperties(properties?: Record<string, any>): Record<string, any> {
    if (!properties) return {};
    
    // Remove potentially sensitive information
    const sanitized: Record<string, any> = {};
    
    Object.entries(properties).forEach(([key, value]) => {
      // Only include non-sensitive metrics
      if (this.isAllowedProperty(key)) {
        sanitized[key] = typeof value === 'string' ? value.substring(0, 100) : value;
      }
    });
    
    return sanitized;
  }
  
  private static isAllowedProperty(key: string): boolean {
    const allowedKeys = [
      'taskCount',
      'completedTasks',
      'theme',
      'reducedMotion',
      'browserType',
      'screenSize',
      'performanceMetric',
      'errorType',
      'componentName'
    ];
    
    const deniedPatterns = [
      /task.*text/i,
      /user.*id/i,
      /email/i,
      /password/i,
      /token/i,
      /session/i
    ];
    
    return allowedKeys.includes(key) && !deniedPatterns.some(pattern => pattern.test(key));
  }
}
```

### Deployment Checklist

Following Elio Struyf's best practices, the deployment process includes comprehensive validation:

```markdown
## Pre-Deployment Checklist

### Code Quality
- [ ] All TypeScript errors resolved
- [ ] Linting passes without errors
- [ ] Test suite passes (100% critical path coverage)
- [ ] Performance budget not exceeded
- [ ] Accessibility audit passes (WCAG 2.1 AA)

### Security
- [ ] No hardcoded secrets in code
- [ ] Content Security Policy configured
- [ ] HTTPS redirect enabled
- [ ] Security headers configured in staticwebapp.config.json

### Performance  
- [ ] Bundle size under 100KB (compressed)
- [ ] First Contentful Paint < 1.5s
- [ ] Lighthouse score > 90 across all categories
- [ ] Images optimized and properly sized

### Azure Configuration
- [ ] Custom domain configured (if applicable)
- [ ] SSL certificate provisioned
- [ ] CDN endpoints configured
- [ ] Application Insights connected
- [ ] Resource tagging completed

### Monitoring
- [ ] Error tracking configured
- [ ] Performance monitoring enabled  
- [ ] Analytics implementation verified
- [ ] Alert rules configured for critical metrics

### Documentation
- [ ] README updated with deployment URLs
- [ ] Architecture documentation current
- [ ] Environment variables documented
- [ ] Rollback procedures documented
```

This deployment strategy ensures reliable, secure, and performant delivery of the Simple To-Do application while maintaining cost efficiency on Azure Static Web Apps' free tier and following industry best practices for CI/CD automation.

---
