# Security Considerations

The Simple To-Do application implements a defense-in-depth security strategy that protects user data, prevents common web vulnerabilities, and prepares for future authentication requirements. This section details security measures for the current MVP and expansion plans.

### Current Security Model (MVP)

The MVP operates as a client-side application with localStorage persistence, requiring specific security considerations:

```typescript
// src/scripts/services/SecurityService.ts - Client-side security utilities
export class SecurityService {
  private static readonly ENCRYPTION_KEY_SIZE = 32;
  private static readonly IV_SIZE = 16;
  
  // Data sanitization for XSS prevention
  static sanitizeInput(input: string): string {
    // HTML encode dangerous characters
    const entityMap: { [key: string]: string } = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
      '/': '&#x2F;',
      '`': '&#96;',
      '=': '&#x3D;'
    };
    
    return input.replace(/[&<>"'`=/]/g, (s) => entityMap[s] || s);
  }
  
  // Input validation with length and content checks
  static validateTaskInput(input: string): {
    isValid: boolean;
    errors: string[];
    sanitized: string;
  } {
    const errors: string[] = [];
    const trimmed = input.trim();
    const sanitized = this.sanitizeInput(trimmed);
    
    // Length validation
    if (trimmed.length === 0) {
      errors.push('Task cannot be empty');
    } else if (trimmed.length > 280) {
      errors.push('Task cannot exceed 280 characters');
    }
    
    // Content validation - detect potential script injection
    const dangerousPatterns = [
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe[^>]*>/i,
      /<object[^>]*>/i,
      /<embed[^>]*>/i
    ];
    
    if (dangerousPatterns.some(pattern => pattern.test(trimmed))) {
      errors.push('Invalid characters detected');
    }
    
    // Unicode validation - prevent homograph attacks
    if (this.containsSuspiciousUnicode(trimmed)) {
      errors.push('Suspicious characters detected');
    }
    
    return {
      isValid: errors.length === 0,
      errors,
      sanitized
    };
  }
  
  // Content Security Policy violation reporting
  static setupCSPReporting(): void {
    document.addEventListener('securitypolicyviolation', (event) => {
      const violation = {
        directive: event.violatedDirective,
        blockedURI: event.blockedURI,
        sourceFile: event.sourceFile,
        lineNumber: event.lineNumber,
        columnNumber: event.columnNumber,
        originalPolicy: event.originalPolicy,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
      };
      
      // Report to monitoring service
      this.reportSecurityIncident('csp_violation', violation);
    });
  }
  
  // Rate limiting for user actions
  static createRateLimiter(maxActions: number, windowMs: number) {
    const actionLog: number[] = [];
    
    return {
      checkLimit: (): boolean => {
        const now = Date.now();
        const windowStart = now - windowMs;
        
        // Remove old entries
        while (actionLog.length > 0 && actionLog[0] < windowStart) {
          actionLog.shift();
        }
        
        // Check if limit exceeded
        if (actionLog.length >= maxActions) {
          this.reportSecurityIncident('rate_limit_exceeded', {
            actions: actionLog.length,
            window: windowMs,
            timestamp: new Date().toISOString()
          });
          return false;
        }
        
        // Log this action
        actionLog.push(now);
        return true;
      }
    };
  }
  
  // Client-side data integrity verification
  static generateDataHash(data: any): string {
    const jsonString = JSON.stringify(data, Object.keys(data).sort());
    return this.simpleHash(jsonString);
  }
  
  static verifyDataIntegrity(data: any, expectedHash: string): boolean {
    const actualHash = this.generateDataHash(data);
    return actualHash === expectedHash;
  }
  
  // localStorage security wrapper
  static secureStorageWrapper = {
    setItem: (key: string, value: string): void => {
      try {
        // Add integrity hash
        const dataWithHash = {
          data: value,
          hash: SecurityService.generateDataHash(value),
          timestamp: Date.now()
        };
        
        localStorage.setItem(key, JSON.stringify(dataWithHash));
      } catch (error) {
        SecurityService.reportSecurityIncident('storage_write_failed', {
          key: key.substring(0, 20), // Don't log full key
          error: error.message
        });
        throw error;
      }
    },
    
    getItem: (key: string): string | null => {
      try {
        const stored = localStorage.getItem(key);
        if (!stored) return null;
        
        const parsed = JSON.parse(stored);
        
        // Verify integrity if hash exists
        if (parsed.hash && !SecurityService.verifyDataIntegrity(parsed.data, parsed.hash)) {
          SecurityService.reportSecurityIncident('data_integrity_violation', {
            key: key.substring(0, 20)
          });
          return null;
        }
        
        return parsed.data || stored; // Backward compatibility
      } catch (error) {
        SecurityService.reportSecurityIncident('storage_read_failed', {
          key: key.substring(0, 20),
          error: error.message
        });
        return null;
      }
    }
  };
  
  // Security incident reporting
  private static reportSecurityIncident(type: string, details: any): void {
    console.warn(`Security incident: ${type}`, details);
    
    if (window.appInsights) {
      window.appInsights.trackEvent({
        name: 'security_incident',
        properties: { type, ...details }
      });
    }
  }
  
  // Utility methods
  private static containsSuspiciousUnicode(text: string): boolean {
    // Check for mixed scripts that could indicate homograph attacks
    const scripts = new Set<string>();
    
    for (const char of text) {
      const script = this.getUnicodeScript(char);
      if (script) scripts.add(script);
    }
    
    // Allow common mixed scripts (Latin + numbers, etc.)
    const allowedMixed = ['Latin', 'Common', 'Inherited'];
    const scriptArray = Array.from(scripts);
    
    return scriptArray.length > 2 && 
           !scriptArray.every(script => allowedMixed.includes(script));
  }
  
  private static getUnicodeScript(char: string): string | null {
    const code = char.codePointAt(0);
    if (!code) return null;
    
    // Simplified script detection for common ranges
    if (code <= 0x007F) return 'Latin';
    if (code >= 0x0080 && code <= 0x00FF) return 'Latin';
    if (code >= 0x0400 && code <= 0x04FF) return 'Cyrillic';
    if (code >= 0x4E00 && code <= 0x9FFF) return 'Han';
    if (code >= 0x3040 && code <= 0x309F) return 'Hiragana';
    if (code >= 0x30A0 && code <= 0x30FF) return 'Katakana';
    
    return 'Common';
  }
  
  private static simpleHash(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString(16);
  }
}
```

### Content Security Policy (CSP)

Comprehensive CSP implementation to prevent XSS and other injection attacks:

```html
<!-- Enhanced CSP headers in staticwebapp.config.json -->
{
  "globalHeaders": {
    "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' https://js.monitor.azure.com https://www.googletagmanager.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://*.applicationinsights.azure.com https://www.google-analytics.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), magnetometer=(), gyroscope=(), speaker=()",
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload"
  }
}
```

### Privacy and Data Protection

GDPR-compliant data handling and user privacy protection:

```typescript
// src/scripts/services/PrivacyService.ts - Privacy compliance utilities
export class PrivacyService {
  private static readonly PRIVACY_VERSION = '1.0';
  private static readonly CONSENT_EXPIRY = 365 * 24 * 60 * 60 * 1000; // 1 year
  
  // Privacy consent management
  static checkPrivacyConsent(): {
    hasConsent: boolean;
    consentVersion: string;
    needsUpdate: boolean;
  } {
    try {
      const consent = localStorage.getItem('privacy-consent');
      if (!consent) {
        return { hasConsent: false, consentVersion: '', needsUpdate: true };
      }
      
      const parsed = JSON.parse(consent);
      const isExpired = Date.now() - parsed.timestamp > this.CONSENT_EXPIRY;
      const needsUpdate = parsed.version !== this.PRIVACY_VERSION || isExpired;
      
      return {
        hasConsent: parsed.accepted && !isExpired,
        consentVersion: parsed.version || '',
        needsUpdate
      };
    } catch {
      return { hasConsent: false, consentVersion: '', needsUpdate: true };
    }
  }
  
  // Record user consent
  static recordConsent(accepted: boolean, preferences: {
    analytics: boolean;
    performance: boolean;
    functional: boolean;
  }): void {
    const consentRecord = {
      accepted,
      preferences,
      version: this.PRIVACY_VERSION,
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      language: navigator.language
    };
    
    localStorage.setItem('privacy-consent', JSON.stringify(consentRecord));
    
    // Configure services based on consent
    this.configurePrivacySettings(preferences);
  }
  
  // Data export for user data portability (GDPR Article 20)
  static exportUserData(): {
    tasks: any[];
    preferences: any;
    metadata: any;
    exportDate: string;
  } {
    try {
      const tasks = JSON.parse(localStorage.getItem('simple-todo:tasks:v1.0') || '{"tasks": []}');
      const preferences = JSON.parse(localStorage.getItem('simple-todo:preferences:v1.0') || '{}');
      const quotes = JSON.parse(localStorage.getItem('simple-todo:quotes:v1.0') || '{}');
      
      // Remove sensitive internal data
      const sanitizedTasks = tasks.tasks?.map((task: any) => ({
        text: task.text,
        completed: task.completed,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        completedAt: task.completedAt
        // Exclude: id, deletedAt (internal data)
      })) || [];
      
      return {
        tasks: sanitizedTasks,
        preferences: {
          theme: preferences.theme,
          reducedMotion: preferences.reducedMotion,
          showQuotes: preferences.showQuotes,
          taskSortOrder: preferences.taskSortOrder
        },
        metadata: {
          taskCount: sanitizedTasks.length,
          completedTasks: sanitizedTasks.filter((t: any) => t.completed).length,
          accountCreated: preferences.lastModified || 'unknown',
          dataVersion: '1.0'
        },
        exportDate: new Date().toISOString()
      };
    } catch (error) {
      console.error('Data export failed:', error);
      throw new Error('Unable to export user data');
    }
  }
  
  // Data deletion for right to be forgotten (GDPR Article 17)
  static deleteAllUserData(): void {
    const keys = Object.keys(localStorage).filter(key => 
      key.startsWith('simple-todo:') || key === 'privacy-consent'
    );
    
    keys.forEach(key => localStorage.removeItem(key));
    
    // Clear any cached data
    if ('caches' in window) {
      caches.keys().then(names => {
        names.forEach(name => caches.delete(name));
      });
    }
    
    // Report data deletion
    console.log('All user data has been deleted');
  }
  
  // Configure services based on privacy preferences
  private static configurePrivacySettings(preferences: {
    analytics: boolean;
    performance: boolean;
    functional: boolean;
  }): void {
    // Configure analytics
    if (!preferences.analytics && window.gtag) {
      window.gtag('config', 'GA_MEASUREMENT_ID', {
        'anonymize_ip': true,
        'allow_google_signals': false,
        'allow_ad_personalization_signals': false
      });
    }
    
    // Configure performance monitoring
    if (!preferences.performance && window.appInsights) {
      window.appInsights.config.samplingPercentage = 0;
    }
    
    // Configure functional features
    if (!preferences.functional) {
      // Disable non-essential localStorage features
      console.log('Non-essential features disabled per user preference');
    }
  }
  
  // Data minimization - clean old data automatically
  static performDataMinimization(): void {
    try {
      const tasks = JSON.parse(localStorage.getItem('simple-todo:tasks:v1.0') || '{"tasks": []}');
      const threeMonthsAgo = Date.now() - (90 * 24 * 60 * 60 * 1000);
      
      // Remove soft-deleted tasks older than 3 months
      const cleanedTasks = tasks.tasks?.filter((task: any) => {
        if (task.deletedAt) {
          return new Date(task.deletedAt).getTime() > threeMonthsAgo;
        }
        return true;
      }) || [];
      
      if (cleanedTasks.length !== tasks.tasks?.length) {
        tasks.tasks = cleanedTasks;
        tasks.lastModified = new Date().toISOString();
        localStorage.setItem('simple-todo:tasks:v1.0', JSON.stringify(tasks));
        
        console.log(`Data minimization: removed ${(tasks.tasks?.length || 0) - cleanedTasks.length} old records`);
      }
    } catch (error) {
      console.error('Data minimization failed:', error);
    }
  }
}
```

### Future Authentication Architecture

Preparation for Azure AD B2C integration when scaling beyond MVP:

```typescript
// src/scripts/services/AuthService.ts - Future authentication service
export class AuthService {
  private static instance: AuthService | null = null;
  private msalInstance: any = null; // Will be MSAL instance
  
  // Singleton pattern for auth service
  static getInstance(): AuthService {
    if (!this.instance) {
      this.instance = new AuthService();
    }
    return this.instance;
  }
  
  // Initialize MSAL for Azure AD B2C (future implementation)
  async initialize(config: {
    clientId: string;
    authority: string;
    redirectUri: string;
  }): Promise<void> {
    // This will be implemented when adding authentication
    console.log('Auth service initialized for future use', config);
  }
  
  // Migration strategy from localStorage to authenticated storage
  async migrateAnonymousData(userId: string): Promise<void> {
    try {
      // Export existing localStorage data
      const anonymousData = PrivacyService.exportUserData();
      
      // Prepare migration payload
      const migrationData = {
        userId,
        anonymousData,
        migrationDate: new Date().toISOString(),
        clientVersion: '1.0'
      };
      
      // In future: send to Azure Functions endpoint
      console.log('Anonymous data prepared for migration:', migrationData);
      
      // For now, keep local data until server confirms migration
      localStorage.setItem('migration-pending', JSON.stringify(migrationData));
      
    } catch (error) {
      console.error('Data migration preparation failed:', error);
      throw new Error('Unable to prepare data for migration');
    }
  }
  
  // Security token validation (future)
  validateToken(token: string): boolean {
    // Will implement JWT validation when adding authentication
    return token.length > 0; // Placeholder
  }
  
  // Secure API communication (future)
  async secureApiCall(endpoint: string, method: string, data?: any): Promise<any> {
    // Will implement authenticated API calls with proper headers
    console.log('Secure API call prepared:', { endpoint, method, data });
    return null; // Placeholder
  }
}
```

### Security Testing & Vulnerability Management

Automated security testing integration:

```yaml
# .github/workflows/security-tests.yml
name: Security Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 3 * * 2' # Weekly on Tuesday at 3 AM

jobs:
  dependency-audit:
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
      
      - name: Run npm audit
        run: |
          cd app
          npm audit --audit-level=moderate
      
      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=medium
          command: test

  csp-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate CSP configuration
        run: |
          # Check for CSP header presence and basic validation
          if grep -q "Content-Security-Policy" staticwebapp.config.json; then
            echo "CSP header found ✓"
          else
            echo "CSP header missing ✗"
            exit 1
          fi

  security-headers:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build application
        run: |
          cd app
          npm ci
          npm run build
      
      - name: Test security headers
        run: |
          # Start local server and test headers
          cd app
          npm run preview &
          SERVER_PID=$!
          sleep 5
          
          # Test security headers
          curl -I http://localhost:4322 | grep -E "(X-Frame-Options|X-Content-Type-Options|Strict-Transport-Security)"
          
          kill $SERVER_PID
```

### Incident Response Plan

Security incident handling procedures:

```markdown
## Security Incident Response Checklist

### Immediate Response (0-1 hour)
- [ ] Identify and isolate affected systems
- [ ] Assess scope and severity of the incident  
- [ ] Preserve evidence and logs
- [ ] Notify key stakeholders
- [ ] Document timeline and actions taken

### Investigation Phase (1-24 hours)
- [ ] Analyze security logs and monitoring data
- [ ] Identify attack vectors and vulnerabilities
- [ ] Assess data exposure and user impact
- [ ] Coordinate with Azure support if needed
- [ ] Prepare initial incident report

### Containment & Recovery (24-72 hours)
- [ ] Apply security patches or configuration fixes
- [ ] Update CSP and security headers if needed
- [ ] Reset any compromised credentials
- [ ] Deploy updated application version
- [ ] Monitor for continued threats

### Post-Incident (1-2 weeks)
- [ ] Conduct thorough security review
- [ ] Update security procedures and policies
- [ ] Implement additional monitoring if needed
- [ ] Provide user communication if required
- [ ] Document lessons learned and improvements
```

This comprehensive security strategy protects the Simple To-Do application against common web vulnerabilities while preparing for future authentication and server-side security requirements. The approach balances current MVP simplicity with enterprise-grade security practices.

---
