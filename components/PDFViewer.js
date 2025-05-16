// components/PDFViewer.js
import React, { useState, useRef, forwardRef, useImperativeHandle } from 'react';
import { StyleSheet, View, PanResponder, Dimensions } from 'react-native';
import Pdf from 'react-native-pdf';
import { toolModes } from '../constants';
import AnnotationMarker from './AnnotationMarker';
import RedactionBox from './RedactionBox';
import CropOverlay from './CropOverlay';

const PDFViewer = forwardRef(({ 
  uri, 
  annotations, 
  redactions, 
  cropArea, 
  mode,
  onTap,
  onDrag
}, ref) => {
  const [pdfDimensions, setPdfDimensions] = useState({ width: 0, height: 0 });
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(0);
  const [scale, setScale] = useState(1);
  const [dragStart, setDragStart] = useState(null);
  const pdfRef = useRef(null);

  // Calculate PDF content dimensions based on device dimensions
  const screenWidth = Dimensions.get('window').width;
  const screenHeight = Dimensions.get('window').height;
  
  // Expose methods to parent component
  useImperativeHandle(ref, () => ({
    getCurrentPage: () => currentPage,
    getTotalPages: () => totalPages
  }));

  const panResponder = PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => mode !== toolModes.VIEW,
    
    onPanResponderGrant: (evt, gestureState) => {
      const { locationX, locationY } = evt.nativeEvent;
      
      if (mode === toolModes.CROP || mode === toolModes.REDACT) {
        setDragStart({ x: locationX, y: locationY });
      } else if (mode === toolModes.ANNOTATE) {
        onTap(currentPage, locationX, locationY, pdfDimensions.width, pdfDimensions.height);
      }
    },
    
    onPanResponderMove: (evt, gestureState) => {
      // Handle drag operations for crop and redact modes
      // Nothing needed here as we're tracking the drag end
    },
    
    onPanResponderRelease: (evt, gestureState) => {
      if (!dragStart) return;
      
      const { locationX, locationY } = evt.nativeEvent;
      
      // Only process if there was significant movement
      const dragDistance = Math.sqrt(
        Math.pow(locationX - dragStart.x, 2) + 
        Math.pow(locationY - dragStart.y, 2)
      );
      
      if (dragDistance > 10) { // Minimum drag distance threshold
        onDrag(
          currentPage,
          dragStart.x,
          dragStart.y,
          locationX,
          locationY,
          pdfDimensions.width,
          pdfDimensions.height
        );
      } else if (mode === toolModes.REDACT) {
        // If the drag was too short, treat it as a tap for redaction
        onTap(currentPage, locationX, locationY, pdfDimensions.width, pdfDimensions.height);
      }
      
      setDragStart(null);
    }
  });

  const handleLoadComplete = (numberOfPages, filePath) => {
    setTotalPages(numberOfPages);
  };

  const handlePageChanged = (page) => {
    setCurrentPage(page);
  };

  const handleError = (error) => {
    console.error('PDF error:', error);
  };

  const renderAnnotations = () => {
    // Only render annotations for the current page
    return annotations
      .filter(ann => ann.pageNumber === currentPage)
      .map((annotation, index) => (
        <AnnotationMarker
          key={`annotation-${index}`}
          x={annotation.x * pdfDimensions.width}
          y={annotation.y * pdfDimensions.height}
          text={annotation.text}
        />
      ));
  };

  const renderRedactions = () => {
    // Only render redactions for the current page
    return redactions
      .filter(red => red.pageNumber === currentPage)
      .map((redaction, index) => (
        <RedactionBox
          key={`redaction-${index}`}
          x={redaction.x * pdfDimensions.width}
          y={redaction.y * pdfDimensions.height}
          width={redaction.width * pdfDimensions.width}
          height={redaction.height * pdfDimensions.height}
        />
      ));
  };

  const renderCropOverlay = () => {
    if (!cropArea || cropArea.pageNumber !== currentPage) return null;
    
    return (
      <CropOverlay
        left={cropArea.left * pdfDimensions.width}
        top={cropArea.top * pdfDimensions.height}
        width={cropArea.width * pdfDimensions.width}
        height={cropArea.height * pdfDimensions.height}
      />
    );
  };

  return (
    <View style={styles.container} {...panResponder.panHandlers}>
      <Pdf
        ref={pdfRef}
        source={{ uri }}
        style={styles.pdf}
        onLoadComplete={handleLoadComplete}
        onPageChanged={handlePageChanged}
        onError={handleError}
        onSize={(width, height) => setPdfDimensions({ width, height })}
        enablePaging={true}
        enableAnnotationRendering={false} // We're handling annotations ourselves
        fitPolicy={0} // Width fit policy
        minScale={0.5}
        maxScale={3.0}
        scale={scale}
      />
      
      {/* Overlay layers for annotations, redactions, and crop area */}
      <View style={[styles.overlayContainer, { width: pdfDimensions.width, height: pdfDimensions.height }]}>
        {renderAnnotations()}
        {renderRedactions()}
        {renderCropOverlay()}
        
        {/* Show drag start indicator if dragging */}
        {dragStart && (mode === toolModes.CROP || mode === toolModes.REDACT) && (
          <View 
            style={[
              styles.dragStart, 
              { left: dragStart.x - 5, top: dragStart.y - 5 }
            ]} 
          />
        )}
      </View>
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-start',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  pdf: {
    flex: 1,
    width: '100%',
    height: '100%',
    backgroundColor: '#ECECEC',
  },
  overlayContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    backgroundColor: 'transparent',
    pointerEvents: 'none',
  },
  dragStart: {
    position: 'absolute',
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: 'rgba(0, 127, 255, 0.7)',
  }
});

export default PDFViewer;
