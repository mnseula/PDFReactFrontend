// components/CropOverlay.js
import React from 'react';
import { StyleSheet, View } from 'react-native';

const CropOverlay = ({ left, top, width, height }) => {
  return (
    <View style={styles.container}>
      {/* Semi-transparent overlay for the entire PDF */}
      <View style={styles.overlay} />
      
      {/* Transparent "hole" for the crop area */}
      <View 
        style={[
          styles.cropArea, 
          {
            left: left,
            top: top,
            width: width,
            height: height,
          }
        ]}
      >
        {/* Corner indicators */}
        <View style={[styles.corner, styles.topLeft]} />
        <View style={[styles.corner, styles.topRight]} />
        <View style={[styles.corner, styles.bottomLeft]} />
        <View style={[styles.corner, styles.bottomRight]} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'transparent',
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  cropArea: {
    position: 'absolute',
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: '#3498db',
  },
  corner: {
    position: 'absolute',
    width: 15,
    height: 15,
    borderColor: '#3498db',
    backgroundColor: 'rgba(255, 255, 255, 0.5)',
  },
  topLeft: {
    top: -2,
    left: -2,
    borderTopWidth: 3,
    borderLeftWidth: 3,
  },
  topRight: {
    top: -2,
    right: -2,
    borderTopWidth: 3,
    borderRightWidth: 3,
  },
  bottomLeft: {
    bottom: -2,
    left: -2,
    borderBottomWidth: 3,
    borderLeftWidth: 3,
  },
  bottomRight: {
    bottom: -2,
    right: -2,
    borderBottomWidth: 3,
    borderRightWidth: 3,
  },
});

export default CropOverlay;
