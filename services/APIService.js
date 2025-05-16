// services/APIService.js
import * as FileSystem from 'expo-file-system';

const API_BASE_URL = 'https://ftp.mikkul.com';

class APIService {
  constructor() {
    this.baseUrl = API_BASE_URL;
  }

  /**
   * Helper method to handle API requests
   * @param {string} endpoint - API endpoint
   * @param {object} data - Request data
   * @returns {Promise<string>} - URI to the resulting PDF file
   */
  async apiRequest(endpoint, data) {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API Error (${response.status}): ${errorText}`);
      }

      // Parse the response as a blob
      const blob = await response.blob();
      
      // Generate a file name using timestamp
      const fileName = `pdf_${Date.now()}.pdf`;
      const fileUri = `${FileSystem.cacheDirectory}${fileName}`;
      
      // Convert blob to base64 string
      const reader = new FileReader();
      reader.readAsDataURL(blob);
      
      return new Promise((resolve, reject) => {
        reader.onloadend = async () => {
          try {
            // Remove data URL prefix (e.g. 'data:application/pdf;base64,')
            const base64Data = reader.result.split(',')[1];
            
            // Write the file to the file system
            await FileSystem.writeAsStringAsync(fileUri, base64Data, {
              encoding: FileSystem.EncodingType.Base64,
            });
            
            resolve(fileUri);
          } catch (error) {
            reject(error);
          }
        };
        
        reader.onerror = () => {
          reject(new Error('Failed to read blob data'));
        };
      });
    } catch (error) {
      console.error('API Request Error:', error);
      throw error;
    }
  }

  /**
   * Compress a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @returns {Promise<string>} - URI to the compressed PDF file
   */
  async compressPDF(base64Pdf) {
    return this.apiRequest('/pdf/compress/', {
      pdf: base64Pdf,
      compressionLevel: 'medium', // can be 'low', 'medium', or 'high'
    });
  }

  /**
   * Perform OCR on a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @returns {Promise<string>} - URI to the OCR'd PDF file
   */
  async ocrPDF(base64Pdf) {
    return this.apiRequest('/pdf/ocr/', {
      pdf: base64Pdf,
      language: 'eng', // OCR language
    });
  }

  /**
   * Edit a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @param {object} edits - Edits to apply
   * @returns {Promise<string>} - URI to the edited PDF file
   */
  async editPDF(base64Pdf, edits) {
    return this.apiRequest('/pdf/edit/', {
      pdf: base64Pdf,
      edits: edits,
    });
  }

  /**
   * Annotate a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @param {Array} annotations - Annotations to add
   * @returns {Promise<string>} - URI to the annotated PDF file
   */
  async annotatePDF(base64Pdf, annotations) {
    // Convert our app's annotation format to the API's expected format
    const apiAnnotations = annotations.map(ann => ({
      page: ann.pageNumber,
      x: ann.x,
      y: ann.y,
      text: ann.text,
      color: '#FFFF00', // Default yellow highlight
      type: 'note', // Default annotation type
    }));

    return this.apiRequest('/pdf/annotate/', {
      pdf: base64Pdf,
      annotations: apiAnnotations,
    });
  }

  /**
   * Crop a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @param {object} cropArea - Crop area coordinates
   * @returns {Promise<string>} - URI to the cropped PDF file
   */
  async cropPDF(base64Pdf, cropArea) {
    return this.apiRequest('/pdf/crop/', {
      pdf: base64Pdf,
      page: cropArea.pageNumber,
      x: cropArea.left,
      y: cropArea.top,
      width: cropArea.width,
      height: cropArea.height,
    });
  }

  /**
   * Redact content in a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @param {Array} redactions - Redaction areas
   * @returns {Promise<string>} - URI to the redacted PDF file
   */
  async redactPDF(base64Pdf, redactions) {
    // Convert our app's redaction format to the API's expected format
    const apiRedactions = redactions.map(red => ({
      page: red.pageNumber,
      x: red.x,
      y: red.y,
      width: red.width,
      height: red.height,
      fillColor: '#000000', // Default black fill
    }));

    return this.apiRequest('/pdf/redact/', {
      pdf: base64Pdf,
      redactions: apiRedactions,
    });
  }

  /**
   * Add watermark to a PDF file
   * @param {string} base64Pdf - PDF file as base64 string
   * @param {string} watermarkText - Watermark text
   * @returns {Promise<string>} - URI to the watermarked PDF file
   */
  async watermarkPDF(base64Pdf, watermarkText) {
    return this.apiRequest('/pdf/watermark/', {
      pdf: base64Pdf,
      text: watermarkText,
      opacity: 0.5,
      rotation: -45, // Degrees
      fontSize: 40,
    });
  }

  /**
   * Convert PDF to Word
   * @param {string} base64Pdf - PDF file as base64 string
   * @returns {Promise<string>} - URI to the resulting Word file
   */
  async pdfToWord(base64Pdf) {
    return this.apiRequest('/pdf/to-word/', {
      pdf: base64Pdf,
    });
  }

  /**
   * Convert PDF to Excel
   * @param {string} base64Pdf - PDF file as base64 string
   * @returns {Promise<string>} - URI to the resulting Excel file
   */
  async pdfToExcel(base64Pdf) {
    return this.apiRequest('/pdf/to-excel/', {
      pdf: base64Pdf,
    });
  }

  /**
   * Convert PDF to JPG
   * @param {string} base64Pdf - PDF file as base64 string
   * @returns {Promise<string>} - URI to the resulting JPG file
   */
  async pdfToJpg(base64Pdf) {
    return this.apiRequest('/pdf/to-jpg/', {
      pdf: base64Pdf,
      quality: 90, // Image quality (0-100)
    });
  }
}

export default APIService;
