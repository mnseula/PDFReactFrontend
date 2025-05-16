// App.js
import React, { useState, useRef, useEffect } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, ActivityIndicator, Alert, ScrollView } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import PDFViewer from './components/PDFViewer';
import ToolBar from './components/ToolBar';
import APIService from './services/APIService';
import { toolModes } from './constants';

export default function App() {
  const [pdfUri, setPdfUri] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [currentMode, setCurrentMode] = useState(toolModes.VIEW);
  const [annotations, setAnnotations] = useState([]);
  const [redactions, setRedactions] = useState([]);
  const [cropArea, setCropArea] = useState(null);
  const [watermarkText, setWatermarkText] = useState('');
  
  const pdfViewerRef = useRef(null);

  const pickPDF = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: 'application/pdf',
        copyToCacheDirectory: true,
      });
      
      if (result.canceled === false) {
        setPdfUri(result.assets[0].uri);
        // Reset all annotations, redactions, etc.
        setAnnotations([]);
        setRedactions([]);
        setCropArea(null);
        setWatermarkText(''); // Reset watermark text
        setCurrentMode(toolModes.VIEW);
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to pick PDF file');
      console.error(error);
    }
  };

  const handleToolChange = (mode) => {
    setCurrentMode(mode);
    if (mode === toolModes.WATERMARK) {
      Alert.prompt(
        'Enter Watermark Text',
        'Please enter the text you want to use as a watermark:',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'OK', onPress: (text) => setWatermarkText(text || '') },
        ],
        'plain-text',
        watermarkText // Default value for the prompt
      );
    }
  };

  const handleTap = (pageNumber, x, y, pageWidth, pageHeight) => {
    // Handle tap based on current mode
    if (currentMode === toolModes.ANNOTATE) {
      // Add annotation at tap location
      const newAnnotation = {
        pageNumber,
        x: x / pageWidth, // Store as ratio for scalability
        y: y / pageHeight,
        text: `Note ${annotations.length + 1}`,
      };
      setAnnotations([...annotations, newAnnotation]);
    } else if (currentMode === toolModes.REDACT) {
      // Add redaction area around tap location
      const redactionWidth = 100 / pageWidth; // Default size in ratio
      const redactionHeight = 30 / pageHeight;
      const newRedaction = {
        pageNumber,
        x: (x / pageWidth) - (redactionWidth / 2),
        y: (y / pageHeight) - (redactionHeight / 2),
        width: redactionWidth,
        height: redactionHeight,
      };
      setRedactions([...redactions, newRedaction]);
    }
  };

  const handleDrag = (pageNumber, startX, startY, endX, endY, pageWidth, pageHeight) => {
    if (currentMode === toolModes.CROP) {
      // Calculate crop area
      const left = Math.min(startX, endX) / pageWidth;
      const top = Math.min(startY, endY) / pageHeight;
      const right = Math.max(startX, endX) / pageWidth;
      const bottom = Math.max(startY, endY) / pageHeight;
      
      setCropArea({
        pageNumber,
        left,
        top,
        right,
        bottom,
        width: right - left,
        height: bottom - top,
      });
    } else if (currentMode === toolModes.REDACT) {
      // Add redaction box from drag gesture
      const left = Math.min(startX, endX) / pageWidth;
      const top = Math.min(startY, endY) / pageHeight;
      const width = Math.abs(endX - startX) / pageWidth;
      const height = Math.abs(endY - startY) / pageHeight;
      
      const newRedaction = {
        pageNumber,
        x: left,
        y: top,
        width,
        height,
      };
      setRedactions([...redactions, newRedaction]);
    }
  };

  const processPDF = async () => {
    if (!pdfUri) {
      Alert.alert('Error', 'Please select a PDF file first');
      return;
    }

    setIsLoading(true);
    try {
      const api = new APIService();
      let resultUri = null;

      // Get the PDF file as base64
      const base64 = await FileSystem.readAsStringAsync(pdfUri, { encoding: FileSystem.EncodingType.Base64 });
      
      switch (currentMode) {
        case toolModes.CROP:
          if (cropArea) {
            resultUri = await api.cropPDF(base64, cropArea);
          } else {
            Alert.alert('Error', 'Please define crop area first');
          }
          break;
          
        case toolModes.ANNOTATE:
          if (annotations.length > 0) {
            resultUri = await api.annotatePDF(base64, annotations);
          } else {
            Alert.alert('Error', 'No annotations to apply');
          }
          break;
          
        case toolModes.REDACT:
          if (redactions.length > 0) {
            resultUri = await api.redactPDF(base64, redactions);
          } else {
            Alert.alert('Error', 'No redactions to apply');
          }
          break;
          
        case toolModes.COMPRESS:
          resultUri = await api.compressPDF(base64);
          break;
          
        case toolModes.OCR:
          resultUri = await api.ocrPDF(base64);
          break;

        case toolModes.WATERMARK:
          if (watermarkText) {
            resultUri = await api.watermarkPDF(base64, { text: watermarkText });
          } else {
            Alert.alert('Error', 'Please set watermark text first via the toolbar');
          }
          break;
          
        default:
          Alert.alert('Error', 'Please select an operation to perform');
      }
      
      if (resultUri) {
        setPdfUri(resultUri);
        Alert.alert('Success', 'PDF processed successfully');
        // Reset interactive elements after successful processing
        // as they are now part of the new PDF
        setAnnotations([]);
        setRedactions([]);
        setCropArea(null);
        // Watermark text can remain if user wants to apply same watermark to another doc
        // or it can be reset: setWatermarkText(''); 
        // For now, we'll keep it. If reset is desired, uncomment the line above.
      }
    } catch (error) {
      Alert.alert('Error', `Failed to process PDF: ${error.message}`);
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <SafeAreaProvider>
      <GestureHandlerRootView style={styles.container}>
        <SafeAreaView style={styles.container}>
          <StatusBar style="auto" />
          
          <View style={styles.header}>
            <Text style={styles.title}>PDF Processor</Text>
          </View>
          
          <View style={styles.toolbarContainer}>
            <ToolBar 
              currentMode={currentMode} 
              onToolChange={handleToolChange} 
            />
          </View>
          
          <View style={styles.actionButtons}>
            <TouchableOpacity style={styles.button} onPress={pickPDF}>
              <Text style={styles.buttonText}>Pick PDF</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={[styles.button, !pdfUri && styles.disabledButton]} 
              onPress={processPDF}
              disabled={!pdfUri}
            >
              <Text style={styles.buttonText}>Process PDF</Text>
            </TouchableOpacity>
          </View>
          
          {isLoading && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color="#0000ff" />
              <Text>Processing...</Text>
            </View>
          )}
          
          <View style={styles.pdfContainer}>
            {pdfUri ? (
              <PDFViewer 
                ref={pdfViewerRef}
                uri={pdfUri}
                annotations={annotations}
                redactions={redactions}
                cropArea={cropArea}
                mode={currentMode}
                onTap={handleTap}
                onDrag={handleDrag}
              />
            ) : (
              <View style={styles.placeholderContainer}>
                <Text style={styles.placeholderText}>Select a PDF to get started</Text>
              </View>
            )}
          </View>
          
          <View style={styles.statusBar}>
            <Text style={styles.statusText}>
              {currentMode === toolModes.VIEW ? 'Viewing mode' : 
               currentMode === toolModes.ANNOTATE ? `Annotations: ${annotations.length}` :
               currentMode === toolModes.REDACT ? `Redactions: ${redactions.length}` :
               currentMode === toolModes.CROP ? 'Define crop area' :
               currentMode === toolModes.COMPRESS ? 'Ready to compress' :
               currentMode === toolModes.OCR ? 'Ready for OCR' :
               currentMode === toolModes.WATERMARK ? `Watermark: "${watermarkText || 'Not set'}"` :
               'Select a tool'}
            </Text>
          </View>
        </SafeAreaView>
      </GestureHandlerRootView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    padding: 15,
    backgroundColor: '#2c3e50',
    alignItems: 'center',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  toolbarContainer: {
    backgroundColor: '#34495e',
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 10,
    backgroundColor: '#ecf0f1',
  },
  button: {
    backgroundColor: '#3498db',
    padding: 10,
    borderRadius: 5,
    minWidth: 120,
    alignItems: 'center',
  },
  disabledButton: {
    backgroundColor: '#95a5a6',
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  pdfContainer: {
    flex: 1,
    backgroundColor: '#ffffff',
    margin: 10,
    borderRadius: 5,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  placeholderContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderText: {
    fontSize: 16,
    color: '#95a5a6',
  },
  loadingContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    zIndex: 999,
  },
  statusBar: {
    padding: 10,
    backgroundColor: '#ecf0f1',
    borderTopWidth: 1,
    borderTopColor: '#ddd',
  },
  statusText: {
    textAlign: 'center',
    color: '#7f8c8d',
  },
});
