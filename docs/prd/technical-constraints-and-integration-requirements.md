# 4. Technical Constraints and Integration Requirements

### 4.1. Existing Technology Stack
The enhancement will be built upon the existing project technology stack:
*   **Frontend**: Astro v5 (Static Site Generation)
*   **Styling**: Tailwind CSS v4
*   **Client-side Scripting**: TypeScript
*   **Backend API**: Azure Functions (Node.js 18+)
*   **Database**: Azure Table Storage (for metadata) and Azure Blob Storage (for markdown content)
*   **Local Development**: Azurite for local Azure Storage emulation

### 4.2. Integration Approach
*   **API Integration**: The `UploadInterface.astro` component will communicate with a new Azure Function (`/api/upload`) via a `POST` request.
*   **Database Integration**:
    *   **Blob Storage**: The API will upload the validated markdown file to the `course-content` container.
    *   **Table Storage**: The API will update the `courses` table with the metadata.
*   **Content Integration**: The solution must adhere to Astro's Content Collections approach.
    *   **Front Matter Enrichment**: The API must enrich the markdown's front matter (e.g., adding `lastUpdated` date).
    *   **API Validation**: The `/api/upload` function is responsible for validating the incoming data against the schema in `app/src/content.config.ts`.

### 4.3. Code Organization and Standards
*   **Component Location**: `app/src/components/UploadInterface.astro`
*   **API Location**: `api/src/functions/UploadCourse/`
*   **Type Safety**: All new code must be strongly typed using TypeScript.

### 4.4. Deployment and CI/CD
*   **Deployment Method**: Deployment is automated via the GitHub Actions workflow in `.github/workflows/azure-static-web-apps-black-tree-0fb59a003.yml`.
*   **Hosting Environment**: The project is hosted on the Azure Static Web App free plan with managed functions available at the `/api` path.

### 4.5. Technical Risk Assessment

| Risk Category | Description | Mitigation Strategy |
| :--- | :--- | :--- |
| **Performance** | Large file uploads could block the UI. | Implement asynchronous uploads with progress indicators. |
| **Security** | Unsanitized markdown could introduce XSS vulnerabilities. | The API must sanitize all incoming markdown content before storing it. |
| **Data Integrity** | An upload might succeed for the blob but fail for the table metadata. | The API function must use a transactional approach: if the Table Storage write fails, the uploaded blob will be deleted. |
| **Architecture** | **Server-Side Rendering (SSR) is not supported** on Azure Static Web Apps. | The application must continue to use Astro's static generation (`output: 'static'`) with `getStaticPaths`. |
| **Dependencies** | **SAS Token Expiration**. In production, `generateSas` is mandatory. Tokens can expire. | The client-side logic must gracefully handle potential 500 errors from the API that could result from an expired SAS token. |

---
