# Performance & Monitoring

The Simple To-Do application implements comprehensive performance optimization and monitoring strategies to ensure excellent user experience across all devices and network conditions. This section details performance budgets, optimization techniques, and observability implementation.

### Performance Budgets & Targets

The application adheres to strict performance budgets aligned with modern web standards and the PRD's performance requirements:

```typescript
// Performance budgets and targets
export const PERFORMANCE_BUDGETS = {
  // Bundle size limits
  javascript: {
    initial: '50KB',    // Gzipped initial JS bundle
    total: '100KB',     // Gzipped total JS (including lazy chunks)
    vendor: '30KB'      // Third-party dependencies
  },
  
  css: {
    initial: '15KB',    // Gzipped initial CSS
    total: '25KB'       // Gzipped total CSS
  },
  
  images: {
    hero: '20KB',       // Hero/above-fold images
    icons: '5KB',       // Icon sets and small graphics
    total: '50KB'       // Total image payload
  },
  
  // Core Web Vitals targets
  coreWebVitals: {
    lcp: 1500,          // Largest Contentful Paint (ms)
    fid: 100,           // First Input Delay (ms)
    cls: 0.1,           // Cumulative Layout Shift
    fcp: 1000,          // First Contentful Paint (ms)
    ttfb: 600           // Time to First Byte (ms)
  },
  
  // Lighthouse targets
  lighthouse: {
    performance: 95,    // Performance score
    accessibility: 100, // Accessibility score
    bestPractices: 100, // Best Practices score
    seo: 100           // SEO score
  },
  
  // Network conditions
  slowNetwork: {
    downloadSpeed: 1.6, // Mbps (3G)
    uploadSpeed: 0.75,  // Mbps
    rtt: 300           // Round-trip time (ms)
  }
} as const;
```

### Frontend Performance Optimization

Comprehensive optimization strategies for client-side performance:

```typescript
// src/scripts/services/PerformanceService.ts - Performance monitoring and optimization
export class PerformanceService {
  private static metrics: Map<string, number> = new Map();
  private static observer: PerformanceObserver | null = null;
  
  // Initialize performance monitoring
  static initialize(): void {
    if (typeof window === 'undefined') return;
    
    this.setupPerformanceObserver();
    this.setupResourceTimingMonitoring();
    this.setupNavigationTimingMonitoring();
    this.measureCoreWebVitals();
  }
  
  // Measure and track Core Web Vitals
  private static measureCoreWebVitals(): void {
    // Largest Contentful Paint (LCP)
    new PerformanceObserver((entryList) => {
      const entries = entryList.getEntries();
      const lastEntry = entries[entries.length - 1];
      
      this.metrics.set('lcp', lastEntry.startTime);
      this.reportMetric('lcp', lastEntry.startTime);
      
      if (lastEntry.startTime > PERFORMANCE_BUDGETS.coreWebVitals.lcp) {
        console.warn(`LCP exceeded budget: ${lastEntry.startTime}ms > ${PERFORMANCE_BUDGETS.coreWebVitals.lcp}ms`);
      }
    }).observe({ entryTypes: ['largest-contentful-paint'] });
    
    // First Input Delay (FID)
    new PerformanceObserver((entryList) => {
      entryList.getEntries().forEach((entry: any) => {
        this.metrics.set('fid', entry.processingStart - entry.startTime);
        this.reportMetric('fid', entry.processingStart - entry.startTime);
      });
    }).observe({ entryTypes: ['first-input'] });
    
    // Cumulative Layout Shift (CLS)
    let clsValue = 0;
    new PerformanceObserver((entryList) => {
      entryList.getEntries().forEach((entry: any) => {
        if (!entry.hadRecentInput) {
          clsValue += entry.value;
        }
      });
      
      this.metrics.set('cls', clsValue);
      this.reportMetric('cls', clsValue);
    }).observe({ entryTypes: ['layout-shift'] });
  }
  
  // Resource loading optimization
  static preloadCriticalResources(): void {
    const criticalResources = [
      { href: '/fonts/inter-var.woff2', as: 'font', type: 'font/woff2', crossorigin: 'anonymous' },
      { href: '/images/app-icon.webp', as: 'image' }
    ];
    
    criticalResources.forEach(resource => {
      const link = document.createElement('link');
      link.rel = 'preload';
      link.href = resource.href;
      link.as = resource.as;
      if (resource.type) link.type = resource.type;
      if (resource.crossorigin) link.crossOrigin = resource.crossorigin;
      
      document.head.appendChild(link);
    });
  }
  
  // Lazy loading implementation
  static setupLazyLoading(): void {
    const imageObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target as HTMLImageElement;
          if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
          }
          observer.unobserve(img);
        }
      });
    }, {
      rootMargin: '50px 0px' // Load images 50px before they come into view
    });
    
    document.querySelectorAll('img[data-src]').forEach(img => {
      imageObserver.observe(img);
    });
  }
  
  // Memory usage monitoring
  static monitorMemoryUsage(): void {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      
      this.metrics.set('memoryUsage', memory.usedJSHeapSize / 1024 / 1024); // MB
      this.reportMetric('memoryUsage', memory.usedJSHeapSize / 1024 / 1024);
      
      // Warn if memory usage is high
      if (memory.usedJSHeapSize / memory.jsHeapSizeLimit > 0.8) {
        console.warn('High memory usage detected');
      }
    }
  }
  
  // Task performance measurement
  static measureTaskOperation<T>(
    operationName: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const startTime = performance.now();
    
    return operation().then(result => {
      const duration = performance.now() - startTime;
      this.metrics.set(operationName, duration);
      this.reportMetric(operationName, duration);
      
      // Log slow operations
      if (duration > 16) { // More than one frame at 60fps
        console.warn(`Slow operation detected: ${operationName} took ${duration.toFixed(2)}ms`);
      }
      
      return result;
    });
  }
  
  private static reportMetric(name: string, value: number): void {
    // Report to analytics service
    if (window.gtag) {
      window.gtag('event', 'performance_metric', {
        metric_name: name,
        metric_value: Math.round(value),
        custom_parameter: name
      });
    }
    
    // Report to Application Insights
    if (window.appInsights) {
      window.appInsights.trackMetric({ name: `performance.${name}`, average: value });
    }
  }
}
```

### Storage Performance Optimization

Optimized localStorage operations with performance monitoring:

```typescript
// Enhanced StorageManager with performance optimization
export class OptimizedStorageManager extends StorageManager {
  private static cache: Map<string, { data: any; timestamp: number; ttl: number }> = new Map();
  private static pendingWrites: Map<string, any> = new Map();
  private static writeTimeout: number | null = null;
  
  // Cached read operations
  static getCachedData<T>(key: string, ttl: number = 5000): T | null {
    const cached = this.cache.get(key);
    
    if (cached && Date.now() - cached.timestamp < cached.ttl) {
      return cached.data;
    }
    
    // Cache miss - read from localStorage
    const startTime = performance.now();
    const data = super.getData<T>(key);
    const readTime = performance.now() - startTime;
    
    if (data) {
      this.cache.set(key, { data, timestamp: Date.now(), ttl });
    }
    
    // Report slow reads
    if (readTime > 5) {
      PerformanceService.reportMetric('storage.read.slow', readTime);
    }
    
    return data;
  }
  
  // Batched write operations
  static setBatchedData(key: string, data: any): void {
    this.pendingWrites.set(key, data);
    
    // Update cache immediately for read consistency
    this.cache.set(key, { data, timestamp: Date.now(), ttl: 5000 });
    
    // Debounce writes
    if (this.writeTimeout) {
      clearTimeout(this.writeTimeout);
    }
    
    this.writeTimeout = window.setTimeout(() => {
      this.flushPendingWrites();
    }, 100); // 100ms debounce
  }
  
  // Flush batched writes
  private static flushPendingWrites(): void {
    const startTime = performance.now();
    const writeCount = this.pendingWrites.size;
    
    try {
      this.pendingWrites.forEach((data, key) => {
        super.setData(key, data);
      });
      
      this.pendingWrites.clear();
      this.writeTimeout = null;
      
      const writeTime = performance.now() - startTime;
      PerformanceService.reportMetric('storage.batch.write', writeTime);
      PerformanceService.reportMetric('storage.batch.count', writeCount);
      
    } catch (error) {
      console.error('Batch write failed:', error);
      PerformanceService.reportMetric('storage.batch.error', 1);
    }
  }
  
  // Storage cleanup with performance tracking
  static performOptimizedCleanup(): CleanupResult {
    const startTime = performance.now();
    const result = super.performCleanup();
    const cleanupTime = performance.now() - startTime;
    
    PerformanceService.reportMetric('storage.cleanup.duration', cleanupTime);
    PerformanceService.reportMetric('storage.cleanup.removed', result.removedTasks);
    
    // Clear relevant cache entries
    this.cache.clear();
    
    return result;
  }
}
```

### Monitoring & Observability Setup

Comprehensive monitoring strategy with multiple data sources:

```typescript
// src/scripts/services/MonitoringService.ts - Centralized monitoring
export class MonitoringService {
  private static errorCount: number = 0;
  private static sessionStart: number = Date.now();
  private static userInteractions: number = 0;
  
  // Initialize all monitoring systems
  static initialize(config: {
    enableAnalytics: boolean;
    enableErrorReporting: boolean;
    analyticsId?: string;
    sentryDsn?: string;
  }): void {
    this.setupErrorTracking(config.enableErrorReporting, config.sentryDsn);
    this.setupUserInteractionTracking();
    this.setupPerformanceMonitoring();
    this.setupHealthChecks();
    
    if (config.enableAnalytics && config.analyticsId) {
      AnalyticsService.initialize(config);
    }
  }
  
  // Error tracking and reporting
  private static setupErrorTracking(enabled: boolean, dsn?: string): void {
    if (!enabled) return;
    
    // Global error handler
    window.addEventListener('error', (event) => {
      this.errorCount++;
      
      const errorInfo = {
        message: event.message,
        filename: event.filename,
        line: event.lineno,
        column: event.colno,
        stack: event.error?.stack,
        timestamp: new Date().toISOString(),
        sessionDuration: Date.now() - this.sessionStart,
        userInteractions: this.userInteractions,
        url: window.location.href
      };
      
      this.reportError('javascript_error', errorInfo);
    });
    
    // Unhandled promise rejection handler
    window.addEventListener('unhandledrejection', (event) => {
      this.errorCount++;
      
      const errorInfo = {
        reason: event.reason?.toString() || 'Unknown promise rejection',
        stack: event.reason?.stack,
        timestamp: new Date().toISOString(),
        sessionDuration: Date.now() - this.sessionStart,
        userInteractions: this.userInteractions,
        url: window.location.href
      };
      
      this.reportError('promise_rejection', errorInfo);
    });
  }
  
  // User interaction tracking
  private static setupUserInteractionTracking(): void {
    const interactionEvents = ['click', 'keydown', 'scroll', 'touchstart'];
    
    interactionEvents.forEach(eventType => {
      document.addEventListener(eventType, () => {
        this.userInteractions++;
      }, { passive: true });
    });
    
    // Report engagement metrics periodically
    setInterval(() => {
      this.reportEngagementMetrics();
    }, 30000); // Every 30 seconds
  }
  
  // Application health monitoring
  private static setupHealthChecks(): void {
    setInterval(() => {
      this.performHealthCheck();
    }, 60000); // Every minute
  }
  
  private static performHealthCheck(): void {
    const healthMetrics = {
      timestamp: new Date().toISOString(),
      sessionDuration: Date.now() - this.sessionStart,
      errorCount: this.errorCount,
      userInteractions: this.userInteractions,
      memoryUsage: this.getMemoryUsage(),
      storageUsage: this.getStorageUsage(),
      connectionType: this.getConnectionInfo(),
      batteryLevel: this.getBatteryInfo()
    };
    
    // Report health metrics
    if (window.appInsights) {
      window.appInsights.trackEvent({
        name: 'health_check',
        properties: healthMetrics
      });
    }
    
    // Log warnings for concerning metrics
    if (this.errorCount > 5) {
      console.warn('High error count detected:', this.errorCount);
    }
    
    if (healthMetrics.memoryUsage && healthMetrics.memoryUsage > 50) {
      console.warn('High memory usage:', healthMetrics.memoryUsage, 'MB');
    }
  }
  
  // System information gathering
  private static getMemoryUsage(): number | null {
    if ('memory' in performance) {
      return Math.round((performance as any).memory.usedJSHeapSize / 1024 / 1024);
    }
    return null;
  }
  
  private static getStorageUsage(): { used: number; available: number } | null {
    try {
      if ('storage' in navigator && 'estimate' in navigator.storage) {
        navigator.storage.estimate().then(estimate => {
          const used = Math.round((estimate.usage || 0) / 1024 / 1024);
          const available = Math.round((estimate.quota || 0) / 1024 / 1024);
          
          PerformanceService.reportMetric('storage.used', used);
          PerformanceService.reportMetric('storage.available', available);
        });
      }
    } catch (error) {
      console.warn('Storage estimation failed:', error);
    }
    return null;
  }
  
  private static getConnectionInfo(): string {
    if ('connection' in navigator) {
      const connection = (navigator as any).connection;
      return `${connection.effectiveType || 'unknown'}_${connection.downlink || 'unknown'}mbps`;
    }
    return 'unknown';
  }
  
  private static getBatteryInfo(): number | null {
    // Battery API is deprecated but might still be available
    if ('getBattery' in navigator) {
      (navigator as any).getBattery().then((battery: any) => {
        PerformanceService.reportMetric('battery.level', Math.round(battery.level * 100));
      });
    }
    return null;
  }
  
  private static reportError(type: string, errorInfo: any): void {
    // Console logging for development
    if (isDevelopment) {
      console.error(`${type}:`, errorInfo);
    }
    
    // Report to monitoring services
    if (window.appInsights) {
      window.appInsights.trackException({
        exception: new Error(errorInfo.message || errorInfo.reason),
        properties: { type, ...errorInfo }
      });
    }
    
    // Report to analytics
    AnalyticsService.trackEvent('error_occurred', {
      errorType: type,
      sessionDuration: errorInfo.sessionDuration,
      userInteractions: errorInfo.userInteractions
    });
  }
  
  private static reportEngagementMetrics(): void {
    const metrics = {
      sessionDuration: Date.now() - this.sessionStart,
      userInteractions: this.userInteractions,
      errorCount: this.errorCount,
      timestamp: new Date().toISOString()
    };
    
    AnalyticsService.trackEvent('engagement_heartbeat', metrics);
  }
}
```

### Performance Testing Strategy

Automated performance validation integrated with the deployment pipeline:

```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1' # Weekly on Monday at 2 AM

jobs:
  lighthouse-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: './app/package-lock.json'
      
      - name: Install dependencies
        run: |
          cd app
          npm ci
          
      - name: Build application
        run: |
          cd app
          npm run build
          
      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          configPath: './.lighthouserc.js'
          uploadArtifacts: true
          temporaryPublicStorage: true
```

```javascript
// .lighthouserc.js - Lighthouse CI configuration
module.exports = {
  ci: {
    collect: {
      staticDistDir: './app/dist',
      numberOfRuns: 3,
      settings: {
        preset: 'perf',
        chromeFlags: '--no-sandbox --headless',
        throttling: {
          rttMs: 40,
          throughputKbps: 10240,
          cpuSlowdownMultiplier: 1,
          requestLatencyMs: 0,
          downloadThroughputKbps: 0,
          uploadThroughputKbps: 0
        }
      }
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.95 }],
        'categories:accessibility': ['error', { minScore: 1.0 }],
        'categories:best-practices': ['error', { minScore: 1.0 }],
        'categories:seo': ['error', { minScore: 1.0 }],
        'first-contentful-paint': ['error', { maxNumericValue: 1000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 1500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }]
      }
    },
    upload: {
      target: 'temporary-public-storage'
    }
  }
};
```

This comprehensive performance and monitoring strategy ensures the Simple To-Do application maintains excellent user experience while providing detailed insights into application health, user engagement, and performance characteristics across all deployment environments.

---
