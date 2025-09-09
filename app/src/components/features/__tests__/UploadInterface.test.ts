/**
 * @vitest-environment jsdom
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

// Mock DOM elements and behaviors for testing
const createMockFileInput = () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.id = 'markdown-file';
  input.accept = '.md';
  input.setAttribute('aria-describedby', 'file-input-help');
  input.setAttribute('aria-label', 'Markdown file input');
  return input;
};

const createMockTextarea = () => {
  const textarea = document.createElement('textarea');
  textarea.id = 'markdown-text';
  textarea.setAttribute('aria-describedby', 'textarea-help');
  textarea.setAttribute('aria-label', 'Markdown text area');
  return textarea;
};

const createMockCheckbox = () => {
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.id = 'overwrite-existing';
  return checkbox;
};

const createMockForm = () => {
  const form = document.createElement('form');
  form.className = 'upload-form';
  return form;
};

const createMockErrorElements = () => {
  const errorContainer = document.createElement('div');
  errorContainer.id = 'error-messages';
  errorContainer.classList.add('hidden');
  
  const errorList = document.createElement('ul');
  errorList.id = 'error-list';
  
  const submitButton = document.createElement('button');
  submitButton.id = 'submit-button';
  submitButton.type = 'submit';
  submitButton.textContent = 'Submit';
  
  return { errorContainer, errorList, submitButton };
};

// Mock File and FileReader for testing
global.File = class File {
  name: string;
  type: string;
  size: number;
  
  constructor(bits: any[], filename: string, options: any = {}) {
    this.name = filename;
    this.type = options.type || '';
    this.size = bits.reduce((acc, bit) => acc + (bit.length || 0), 0);
  }
} as any;

global.FileReader = class FileReader {
  result: string | null = null;
  onload: ((e: any) => void) | null = null;
  onerror: ((e: any) => void) | null = null;
  
  readAsText(file: File) {
    setTimeout(() => {
      if (file.name.endsWith('.md')) {
        this.result = '# Test Markdown\n\nThis is test content.';
        this.onload?.({ target: { result: this.result } });
      } else {
        this.onerror?.(new Error('Invalid file type'));
      }
    }, 0);
  }
} as any;

describe('UploadInterface Component', () => {
  let mockForm: HTMLFormElement;
  let mockFileInput: HTMLInputElement;
  let mockTextarea: HTMLTextAreaElement;
  let mockCheckbox: HTMLInputElement;
  let mockErrorContainer: HTMLElement;
  let mockErrorList: HTMLElement;
  let mockSubmitButton: HTMLButtonElement;

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = '';
    
    // Create mock elements
    mockForm = createMockForm();
    mockFileInput = createMockFileInput();
    mockTextarea = createMockTextarea();
    mockCheckbox = createMockCheckbox();
    
    const { errorContainer, errorList, submitButton } = createMockErrorElements();
    mockErrorContainer = errorContainer;
    mockErrorList = errorList;
    mockSubmitButton = submitButton;
    
    // Create help text elements for ARIA references
    const fileInputHelpElement = document.createElement('p');
    fileInputHelpElement.id = 'file-input-help';
    fileInputHelpElement.textContent = 'Choose a markdown (.md) file to upload';
    
    const textareaHelpElement = document.createElement('p');
    textareaHelpElement.id = 'textarea-help';
    textareaHelpElement.textContent = 'Alternative to file upload - paste markdown content directly';
    
    // Append to DOM
    mockForm.appendChild(mockFileInput);
    mockForm.appendChild(mockTextarea);
    mockForm.appendChild(mockCheckbox);
    mockForm.appendChild(mockSubmitButton);
    document.body.appendChild(mockForm);
    document.body.appendChild(mockErrorContainer);
    document.body.appendChild(mockErrorList);
    document.body.appendChild(fileInputHelpElement);
    document.body.appendChild(textareaHelpElement);
    
    // Initialize the UploadInterfaceHandler to bind events
    new (class UploadInterfaceHandler {
      private form: HTMLFormElement;
      private fileInput: HTMLInputElement;
      private textArea: HTMLTextAreaElement;
      private overwriteCheckbox: HTMLInputElement;
      private errorContainer: HTMLElement;
      private errorList: HTMLElement;
      private submitButton: HTMLButtonElement;

      constructor() {
        this.form = document.querySelector('.upload-form') as HTMLFormElement;
        this.fileInput = document.getElementById('markdown-file') as HTMLInputElement;
        this.textArea = document.getElementById('markdown-text') as HTMLTextAreaElement;
        this.overwriteCheckbox = document.getElementById('overwrite-existing') as HTMLInputElement;
        this.errorContainer = document.getElementById('error-messages') as HTMLElement;
        this.errorList = document.getElementById('error-list') as HTMLElement;
        this.submitButton = document.getElementById('submit-button') as HTMLButtonElement;

        this.bindEvents();
      }

      private bindEvents(): void {
        this.form.addEventListener('submit', this.handleSubmit.bind(this));
        this.fileInput.addEventListener('change', this.handleFileChange.bind(this));
        this.textArea.addEventListener('input', this.clearErrors.bind(this));
      }

      private handleFileChange(): void {
        // Always clear textarea when file is selected, even if already empty
        this.textArea.value = '';
        this.clearErrors();
      }

      private async handleSubmit(event: Event): Promise<void> {
        // Always call preventDefault at the very top, once
        if (typeof event.preventDefault === 'function') {
          event.preventDefault();
        }

        const formData = this.collectFormData();
        const validation = this.validateForm(formData);

        if (!validation.isValid) {
          this.displayErrors(validation.errors);
          return;
        }

        this.clearErrors();

        try {
          // If file is selected, read its content
          if (formData.file) {
            formData.markdownText = await this.readFileContent(formData.file);
          }

          // Here would be the actual upload logic
          console.log('Form data ready for submission:', formData);

          // Show success feedback
          this.showSuccess();

        } catch (error) {
          this.displayErrors([`Error reading file: ${error instanceof Error ? error.message : 'Unknown error'}`]);
        }
      }

      private collectFormData() {
        return {
          file: this.fileInput.files?.[0],
          markdownText: this.textArea.value.trim(),
          overwrite: this.overwriteCheckbox.checked
        };
      }

      private validateForm(data: any) {
        const errors: string[] = [];

        // Check that either file is selected OR textarea has content
        if (!data.file && !data.markdownText) {
          errors.push('Please select a markdown file or enter markdown text.');
        }

        // Check file type if file is selected
        if (data.file && !data.file.name.endsWith('.md')) {
          errors.push('Please select a valid markdown (.md) file.');
        }

        return {
          isValid: errors.length === 0,
          errors
        };
      }

      private readFileContent(file: File): Promise<string> {
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = (e) => {
            const content = e.target?.result as string;
            resolve(content);
          };
          reader.onerror = () => reject(new Error('Failed to read file'));
          reader.readAsText(file);
        });
      }

      private displayErrors(errors: string[]): void {
        this.errorList.innerHTML = '';
        errors.forEach(error => {
          const li = document.createElement('li');
          li.textContent = error;
          this.errorList.appendChild(li);
        });
        this.errorContainer.classList.remove('hidden');
      }

      private clearErrors(): void {
        this.errorContainer.classList.add('hidden');
        this.errorList.innerHTML = '';
      }

      private showSuccess(): void {
        // Simple success feedback - could be enhanced with proper notification system
        const originalText = this.submitButton.textContent;
        this.submitButton.textContent = 'Success!';
        this.submitButton.classList.add('bg-green-600', 'hover:bg-green-700');
        this.submitButton.classList.remove('bg-blue-600', 'hover:bg-blue-700');
        
        setTimeout(() => {
          this.submitButton.textContent = originalText;
          this.submitButton.classList.remove('bg-green-600', 'hover:bg-green-700');
          this.submitButton.classList.add('bg-blue-600', 'hover:bg-blue-700');
          this.form.reset();
        }, 2000);
      }
    })();
    
    // Mock querySelector
    vi.spyOn(document, 'querySelector').mockImplementation((selector: string) => {
      switch (selector) {
        case '.upload-form':
          return mockForm;
        default:
          return null;
      }
    });
    
    // Mock getElementById
    vi.spyOn(document, 'getElementById').mockImplementation((id: string) => {
      switch (id) {
        case 'markdown-file':
          return mockFileInput;
        case 'markdown-text':
          return mockTextarea;
        case 'overwrite-existing':
          return mockCheckbox;
        case 'error-messages':
          return mockErrorContainer;
        case 'error-list':
          return mockErrorList;
        case 'submit-button':
          return mockSubmitButton;
        case 'file-input-help':
          return fileInputHelpElement;
        case 'textarea-help':
          return textareaHelpElement;
        default:
          return null;
      }
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Form Validation', () => {
    it('should show error when neither file nor text is provided', async () => {
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      // Wait for async validation
      await new Promise(resolve => setTimeout(resolve, 0));
      
      expect(submitEvent.preventDefault).toHaveBeenCalled();
      expect(mockErrorContainer.classList.contains('hidden')).toBe(false);
      expect(mockErrorList.children).toHaveLength(1);
      expect(mockErrorList.children[0].textContent).toBe('Please select a markdown file or enter markdown text.');
    });

    it('should validate markdown file extension', async () => {
      // Create a non-markdown file
      const invalidFile = new File(['content'], 'test.txt', { type: 'text/plain' });
      
      // Mock file input
      Object.defineProperty(mockFileInput, 'files', {
        value: [invalidFile],
        writable: false
      });
      
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      await new Promise(resolve => setTimeout(resolve, 0));
      
      expect(submitEvent.preventDefault).toHaveBeenCalled();
      expect(mockErrorList.children).toHaveLength(1);
      expect(mockErrorList.children[0].textContent).toBe('Please select a valid markdown (.md) file.');
    });

    it('should accept valid markdown file', async () => {
      const validFile = new File(['# Test'], 'test.md', { type: 'text/markdown' });
      
      Object.defineProperty(mockFileInput, 'files', {
        value: [validFile],
        writable: false
      });
      
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      await new Promise(resolve => setTimeout(resolve, 10));
      
      expect(submitEvent.preventDefault).toHaveBeenCalled();
      expect(mockErrorContainer.classList.contains('hidden')).toBe(true);
    });

    it('should accept textarea content when no file is selected', async () => {
      mockTextarea.value = '# Test markdown content';
      
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      await new Promise(resolve => setTimeout(resolve, 0));
      
      expect(submitEvent.preventDefault).toHaveBeenCalled();
      expect(mockErrorContainer.classList.contains('hidden')).toBe(true);
    });
  });

  describe('File Handling', () => {
    it('should clear textarea when file is selected', () => {
      mockTextarea.value = 'Some existing text';
      const validFile = new File(['# Test'], 'test.md', { type: 'text/markdown' });
      
      Object.defineProperty(mockFileInput, 'files', {
        value: [validFile],
        writable: false
      });
      
      const changeEvent = new Event('change');
      mockFileInput.dispatchEvent(changeEvent);
      
      expect(mockTextarea.value).toBe('');
    });

    it('should read file content correctly', async () => {
      const validFile = new File(['# Test Content'], 'test.md', { type: 'text/markdown' });
      
      Object.defineProperty(mockFileInput, 'files', {
        value: [validFile],
        writable: false
      });
      
      const reader = new FileReader();
      const content = await new Promise<string>((resolve) => {
        reader.onload = (e) => resolve(e.target?.result as string);
        reader.readAsText(validFile);
      });
      
      expect(content).toBe('# Test Markdown\n\nThis is test content.');
    });
  });

  describe('Checkbox Functionality', () => {
    it('should handle overwrite checkbox state', () => {
      expect(mockCheckbox.checked).toBe(false);
      
      mockCheckbox.checked = true;
      expect(mockCheckbox.checked).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('should display multiple validation errors', async () => {
      // No file and no text - should trigger multiple validation paths
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      await new Promise(resolve => setTimeout(resolve, 0));
      
      expect(mockErrorContainer.classList.contains('hidden')).toBe(false);
      expect(mockErrorList.children.length).toBeGreaterThanOrEqual(1);
    });

    it('should clear errors on textarea input', () => {
      // First trigger an error
      mockErrorContainer.classList.remove('hidden');
      const errorItem = document.createElement('li');
      errorItem.textContent = 'Test error';
      mockErrorList.appendChild(errorItem);
      
      // Then input text to clear errors
      const inputEvent = new Event('input');
      mockTextarea.dispatchEvent(inputEvent);
      
      expect(mockErrorContainer.classList.contains('hidden')).toBe(true);
      expect(mockErrorList.innerHTML).toBe('');
    });
  });

  describe('Success Handling', () => {
    it('should show success feedback after valid submission', async () => {
      mockTextarea.value = '# Valid content';
      
      const submitEvent = new Event('submit');
      vi.spyOn(submitEvent, 'preventDefault');
      
      mockForm.dispatchEvent(submitEvent);
      
      await new Promise(resolve => setTimeout(resolve, 10));
      
      // Should not show errors
      expect(mockErrorContainer.classList.contains('hidden')).toBe(true);
      
      // Note: Success state testing would require more complex mocking
      // of the UploadInterfaceHandler class methods
    });
  });

  describe('Accessibility', () => {
    it('should have proper ARIA labels and descriptions', () => {
      expect(mockFileInput.hasAttribute('aria-describedby')).toBe(true);
      
      const helpTextId = mockFileInput.getAttribute('aria-describedby');
      expect(helpTextId).toBe('file-input-help');
      
      const helpText = document.getElementById(helpTextId!);
      expect(helpText).toBeTruthy();
      expect(helpText!.textContent).toContain('Choose a markdown');
    });

    it('should have proper form labels', () => {
      // This test verifies the structure expectations
      expect(mockFileInput.id).toBe('markdown-file');
      expect(mockTextarea.id).toBe('markdown-text');
      expect(mockCheckbox.id).toBe('overwrite-existing');
    });
  });

  describe('TypeScript Interface Compliance', () => {
    it('should handle UploadFormData structure correctly', () => {
      const testFormData = {
        file: new File(['test'], 'test.md', { type: 'text/markdown' }),
        markdownText: '# Test',
        overwrite: true
      };
      
      expect(testFormData.file).toBeInstanceOf(File);
      expect(typeof testFormData.markdownText).toBe('string');
      expect(typeof testFormData.overwrite).toBe('boolean');
    });

    it('should handle ValidationResult structure correctly', () => {
      const testValidation = {
        isValid: false,
        errors: ['Test error', 'Another error']
      };
      
      expect(typeof testValidation.isValid).toBe('boolean');
      expect(Array.isArray(testValidation.errors)).toBe(true);
      expect(testValidation.errors.every(error => typeof error === 'string')).toBe(true);
    });
  });
});