// components/RedactionBox.js
import React from 'react';
import { StyleSheet, View } from 'react-native';

const RedactionBox = ({ x, y, width, height }) => {
  return (
    <View 
      style={[
        styles.redactionBox, 
        { 
          left: x, 
          top: y, 
          width: width, 
          height: height 
        }
      ]} 
    />
  );
};

const styles = StyleSheet.create({
  redactionBox: {
    position: 'absolute',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderWidth: 1,
    borderColor: 'rgba(255, 0, 0, 0.7)',
    borderStyle: 'dashed',
  },
});

export default RedactionBox;
