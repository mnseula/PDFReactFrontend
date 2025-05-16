// /Users/michaelnseula/Downloads/PDFReactFrontend/services/APIService.js
// Replace with your actual API base URL, e.g., 'http://localhost:3000/api'
const API_BASE_URL = 'https://ftp.mikkul.com'; 

class APIService {
  constructor() {
    // If you use a library like axios, you might initialize it here
    // this.apiClient = axios.create({ baseURL: API_BASE_URL });
  }

  async _callApi(endpoint, method = 'POST', body = {}) {
    console.log(`Attempting API Call: ${method} ${API_BASE_URL}${endpoint}`, body);
    
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          // Add other headers like Authorization if needed
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        let errorData;
        try {
          // Try to parse error as JSON, which is common
          errorData = await response.json();
        } catch (e) {
          // If not JSON, use text
          errorData = await response.text();
        }
        console.error('API Error Response:', errorData);
        const errorMessage = (typeof errorData === 'object' && errorData.message) ? errorData.message : 
                             (typeof errorData === 'string' && errorData) ? errorData :
                             `API request failed with status ${response.status}`;
        throw new Error(errorMessage);
      }

      // Assuming backend returns JSON with a URI like { "processedPdfUri": "some_uri" }
      // or { "resultUri": "some_uri" }
      const responseData = await response.json(); 
      console.log('API Success Response:', responseData);

      // Adjust this based on your backend's actual response structure
      if (responseData.processedPdfUri) {
        return responseData.processedPdfUri;
      } else if (responseData.resultUri) {
        return responseData.resultUri;
      } else {
        // If the backend returns the URI directly or in a different key
        console.warn('processedPdfUri or resultUri not found in response, attempting to find a URI...');
        for (const key in responseData) {
            if (typeof responseData[key] === 'string' && (responseData[key].startsWith('http') || responseData[key].startsWith('file:'))) {
                console.warn(`Using potential URI from key: ${key}`);
                return responseData[key];
            }
        }
        throw new Error('No valid URI found in API response for the processed PDF.');
      }

    } catch (error) {
      console.error('API Call Error in _callApi:', error.message);
      // Re-throw the error so it can be caught by the calling function in App.js
      throw error;
    }
  }

  async cropPDF(base64Pdf, cropArea) {
    console.log('APIService.cropPDF called with cropArea:', cropArea);
    return this._callApi('/pdf/crop', 'POST', { pdfData: base64Pdf, area: cropArea });
  }

  async annotatePDF(base64Pdf, annotations) {
    console.log('APIService.annotatePDF called with annotations:', annotations);
    return this._callApi('/pdf/annotate', 'POST', { pdfData: base64Pdf, annotations: annotations });
  }

  async redactPDF(base64Pdf, redactions) {
    console.log('APIService.redactPDF called with redactions:', redactions);
    return this._callApi('/pdf/redact', 'POST', { pdfData: base64Pdf, redactions: redactions });
  }

  async compressPDF(base64Pdf) {
    console.log('APIService.compressPDF called');
    return this._callApi('/pdf/compress', 'POST', { pdfData: base64Pdf });
  }

  async ocrPDF(base64Pdf) {
    console.log('APIService.ocrPDF called');
    return this._callApi('/pdf/ocr', 'POST', { pdfData: base64Pdf });
  }

  async watermarkPDF(base64Pdf, watermarkOptions) {
    console.log('APIService.watermarkPDF called with options:', watermarkOptions);
    return this._callApi('/pdf/watermark', 'POST', { 
      pdfData: base64Pdf, 
      text: watermarkOptions.text,
      // You might add other options here like font, size, color, opacity, position
      // that your backend expects
    });
  }
}

export default APIService;
