# 5. Epic and Story Structure

### Epic: Enable Course Content Upload and Management

> As a Content Manager, I want to be able to upload and manage course markdown files directly through a web interface, so that I can update course content without needing developer assistance or manual file transfers.

---

### User Stories:

**Story 1: Create the File Upload Interface**
*   **As a** Content Manager, **I want** a simple user interface on a dedicated admin page, **So that** I can select a markdown file or paste markdown text to be uploaded.
*   **Acceptance Criteria:**
    *   A new Astro component (`UploadInterface.astro`) is created.
    *   The interface contains a file input for `.md` files and a `<textarea>`.
    *   A "Submit" button and an "Overwrite existing file?" checkbox are present.

**Story 2: Implement the Backend Upload API Endpoint**
*   **As a** Developer, **I want** a secure API endpoint (`/api/upload`), **So that** it can receive and process the markdown content on the server.
*   **Acceptance Criteria:**
    *   A new Azure Function is created at `api/src/functions/UploadCourse/`.
    *   The function responds to `POST` requests at the `/api/upload` route.
    *   It correctly receives content from the request body and validates it is not empty.

**Story 3: Add Front Matter Validation and Enrichment**
*   **As a** Developer, **I want** the API to parse, validate, and enrich the markdown's front matter, **So that** all content adheres to the `content.config.ts` schema.
*   **Acceptance Criteria:**
    *   The API successfully parses the front matter.
    *   It validates all required fields and types.
    *   It enriches the `lastUpdated` field.
    *   Returns a `400 Bad Request` with a clear message if validation fails.

**Story 4: Implement Blob and Table Storage Logic**
*   **As a** Developer, **I want** the API to save the file to Blob Storage and its metadata to Table Storage, **So that** the new content is persisted and discoverable.
*   **Acceptance Criteria:**
    *   The API constructs the blob name (`{courseId}-{format}.md`).
    *   The content is uploaded to the `course-content` blob container.
    *   The metadata is saved to the `courses` Azure Table.
    *   The operation is atomic (blob is deleted if table write fails).

**Story 5: Implement Client-Side Upload Logic and User Feedback**
*   **As a** Content Manager, **I want** to see the status of my upload, **So that** I know if the operation was successful or if there was a problem.
*   **Acceptance Criteria:**
    *   Client-side TypeScript handles the `fetch` request.
    *   The UI displays a loading indicator.
    *   A confirmation dialog appears if "Overwrite" is checked.
    *   Success or error messages from the API are displayed to the user.

**Story 6: Create Admin Page and Integrate Component**
*   **As a** Developer, **I want** to create a new, non-public admin page, **So that** the upload interface is accessible to authorized users.
*   **Acceptance Criteria:**
    *   A new page is created at `app/src/pages/admin/upload.astro`.
    *   The `UploadInterface.astro` component is embedded and functional.
    *   The page is not linked from any public-facing navigation.
