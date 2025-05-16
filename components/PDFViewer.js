// /Users/michaelnseula/Downloads/PDFReactFrontend/components/PDFViewer.js
import React, { useState, useRef, forwardRef, useImperativeHandle } from 'react';
import { View, StyleSheet, Text, Dimensions, Platform } from 'react-native';
import Pdf from 'react-native-pdf';
import { TapGestureHandler, PanGestureHandler, State } from 'react-native-gesture-handler';

const PDFViewer = forwardRef(({
  uri,
  annotations = [],
  redactions = [],
  cropArea = null,
  // mode, // mode prop is available if needed for specific gesture logic
  onTap,
  onDrag,
}, ref) => {
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageWidth, setPageWidth] = useState(0);
  const [pageHeight, setPageHeight] = useState(0);

  const panStartCoords = useRef({ x: 0, y: 0 });
  const pdfRef = useRef(null);

  // useImperativeHandle can be used to expose functions to the parent component via ref
  useImperativeHandle(ref, () => ({
    // Example: jumpToPage: (pageNumber) => pdfRef.current?.setPage(pageNumber),
  }));

  const source = { uri, cache: true };

  const handlePdfLoadComplete = (numberOfPages, filePath, { width, height }) => {
    setTotalPages(numberOfPages);
    // Use the dimensions of the first page as initial dimensions
    setPageWidth(width);
    setPageHeight(height);
    setCurrentPage(1); // Ensure we are on page 1
    if (pdfRef.current) {
        pdfRef.current.setPage(1);
    }
  };

  const handlePageChanged = (page, numberOfPages, { width, height }) => {
    setCurrentPage(page);
    // Update dimensions if they change per page (e.g., mixed orientations)
    setPageWidth(width);
    setPageHeight(height);
  };

  const handleSingleTapStateChange = (event) => {
    if (event.nativeEvent.state === State.END) { // Tap gesture has ended
      const { x, y } = event.nativeEvent;
      if (onTap && pageWidth > 0 && pageHeight > 0) {
        onTap(currentPage, x, y, pageWidth, pageHeight);
      }
    }
  };

  const handlePanStateChange = (event) => {
    const { x, y, state, oldState } = event.nativeEvent;

    if (state === State.BEGAN) {
      panStartCoords.current = { x, y };
    } else if (oldState === State.ACTIVE && (state === State.END || state === State.CANCELLED || state === State.FAILED)) {
      if (onDrag && pageWidth > 0 && pageHeight > 0) {
        onDrag(
          currentPage,
          panStartCoords.current.x,
          panStartCoords.current.y,
          x, // last known x
          y, // last known y
          pageWidth,
          pageHeight
        );
      }
    }
  };

  const renderOverlays = () => {
    if (pageWidth === 0 || pageHeight === 0) return null;

    // Filter items for the current page
    const pageAnnotations = annotations.filter(a => a.pageNumber === currentPage);
    const pageRedactions = redactions.filter(r => r.pageNumber === currentPage);
    let pageCropArea = null;
    if (cropArea && cropArea.pageNumber === currentPage) {
      pageCropArea = cropArea;
    }

    return (
      <View style={StyleSheet.absoluteFillObject} pointerEvents="box-none">
        {pageAnnotations.map((anno, index) => (
          <View
            key={`anno-${index}-${anno.x}-${anno.y}`}
            style={[
              styles.annotation,
              {
                left: anno.x * pageWidth,
                top: anno.y * pageHeight,
              },
            ]}
          >
            <Text style={styles.annotationText}>{anno.text}</Text>
          </View>
        ))}
        {pageRedactions.map((redact, index) => (
          <View
            key={`redact-${index}-${redact.x}-${redact.y}`}
            style={[
              styles.redaction,
              {
                left: redact.x * pageWidth,
                top: redact.y * pageHeight,
                width: redact.width * pageWidth,
                height: redact.height * pageHeight,
              },
            ]}
          />
        ))}
        {pageCropArea && (
          <View
            style={[
              styles.cropArea,
              {
                left: pageCropArea.left * pageWidth,
                top: pageCropArea.top * pageHeight,
                width: pageCropArea.width * pageWidth,
                height: pageCropArea.height * pageHeight,
              },
            ]}
          />
        )}
      </View>
    );
  };

  if (!uri) {
    return (
      <View style={[styles.pdfWrapper, styles.placeholder]}>
        <Text>No PDF URI provided.</Text>
      </View>
    );
  }

  return (
    <PanGestureHandler
      onHandlerStateChange={handlePanStateChange}
      minDist={10} // Minimum movement before pan activates
    >
      <View style={styles.gestureContainer}>
        <TapGestureHandler
          onHandlerStateChange={handleSingleTapStateChange}
          numberOfTaps={1}
        >
          <View style={styles.pdfWrapper}>
            <Pdf
              ref={pdfRef}
              source={source}
              onLoadComplete={handlePdfLoadComplete}
              onPageChanged={handlePageChanged}
              onError={(error) => {
                console.error('PDF Error:', error);
                // Alert.alert('PDF Error', 'Could not load PDF.');
              }}
              style={styles.pdf}
              trustAllCerts={Platform.OS === 'ios'} // For iOS, if using self-signed certs for remote URIs. Not relevant for local file URIs.
              // horizontal={false} // Set to true for horizontal layout
              // enablePaging={true} // Snaps to page boundaries
            />
            {renderOverlays()}
          </View>
        </TapGestureHandler>
      </View>
    </PanGestureHandler>
  );
});

const styles = StyleSheet.create({
  gestureContainer: {
    flex: 1,
  },
  pdfWrapper: {
    flex: 1,
    backgroundColor: '#e0e0e0', // Background for the PDF area
    position: 'relative', // Needed for absolute positioning of overlays
  },
  placeholder: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  pdf: {
    flex: 1,
    width: Dimensions.get('window').width, // Or adjust if PDFViewer is not full width
    // height: Dimensions.get('window').height, // flex: 1 should handle height
  },
  annotation: {
    position: 'absolute',
    backgroundColor: 'rgba(255, 255, 0, 0.5)', // Semi-transparent yellow
    padding: 3,
    borderRadius: 3,
    borderWidth: 0.5,
    borderColor: '#cca300',
  },
  annotationText: {
    fontSize: 10,
    color: '#333',
  },
  redaction: {
    position: 'absolute',
    backgroundColor: 'black',
  },
  cropArea: {
    position: 'absolute',
    borderWidth: 1.5,
    borderColor: 'rgba(0, 0, 255, 0.7)',
    backgroundColor: 'rgba(0, 0, 255, 0.15)',
  },
});

export default PDFViewer;