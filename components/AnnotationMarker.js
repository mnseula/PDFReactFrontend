// components/AnnotationMarker.js
import React from 'react';
import { StyleSheet, View, Text } from 'react-native';

const AnnotationMarker = ({ x, y, text }) => {
  return (
    <View style={[styles.annotationContainer, { left: x - 10, top: y - 10 }]}>
      <View style={styles.marker} />
      <View style={styles.textBubble}>
        <Text style={styles.text}>{text}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  annotationContainer: {
    position: 'absolute',
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  marker: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 230, 0, 0.8)',
    borderWidth: 2,
    borderColor: 'rgba(255, 200, 0, 1)',
  },
  textBubble: {
    position: 'absolute',
    top: -40,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 5,
    padding: 5,
    borderWidth: 1,
    borderColor: '#ddd',
    minWidth: 60,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 1,
    elevation: 2,
  },
  text: {
    fontSize: 12,
    textAlign: 'center',
  },
});

export default AnnotationMarker;
