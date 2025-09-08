/**
 * TypeScript type definitions for the Simple To-Do application
 */

export interface UploadInterfaceProps {
  onSubmit?: (data: UploadFormData) => void;
  onError?: (error: string) => void;
}

export interface UploadFormData {
  file?: File;
  markdownText: string;
  overwrite: boolean;
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}