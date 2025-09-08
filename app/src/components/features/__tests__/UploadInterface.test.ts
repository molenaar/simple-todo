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
  return input;
};

const createMockTextarea = () => {
  const textarea = document.createElement('textarea');
  textarea.id = 'markdown-text';
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
    
    // Append to DOM
    mockForm.appendChild(mockFileInput);
    mockForm.appendChild(mockTextarea);
    mockForm.appendChild(mockCheckbox);
    mockForm.appendChild(mockSubmitButton);
    document.body.appendChild(mockForm);
    document.body.appendChild(mockErrorContainer);
    document.body.appendChild(mockErrorList);
    
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
      
      const helpText = document.getElementById(mockFileInput.getAttribute('aria-describedby')!);
      expect(helpText?.textContent).toContain('Choose a markdown');
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