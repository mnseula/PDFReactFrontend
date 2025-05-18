// components/ToolBar.js
import React from 'react';
import { StyleSheet, View, TouchableOpacity, Text, ScrollView } from 'react-native';
import { toolModes } from '../constants';

const ToolBar = ({ currentMode, onToolChange }) => {
  const renderToolButton = (mode, label) => {
    const isActive = currentMode === mode;
    return (
      <TouchableOpacity
        style={[styles.toolButton, isActive && styles.activeToolButton]}
        onPress={() => onToolChange(mode)}
      >
        <Text style={[styles.toolButtonText, isActive && styles.activeToolButtonText]}>
          {label}
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.toolBar}>
      {renderToolButton(toolModes.VIEW, 'View')}
      {renderToolButton(toolModes.CROP, 'Crop')}
      {renderToolButton(toolModes.ANNOTATE, 'Annotate')}
      {renderToolButton(toolModes.REDACT, 'Redact')}
      {renderToolButton(toolModes.COMPRESS, 'Compress')}
      {renderToolButton(toolModes.OCR, 'OCR')}
      {renderToolButton(toolModes.WATERMARK, 'Watermark')}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  toolBar: {
    flexDirection: 'row',
    padding: 10,
  },
  toolButton: {
    paddingVertical: 8,
    paddingHorizontal: 15,
    marginRight: 10,
    borderRadius: 5,
    backgroundColor: '#455a64',
  },
  activeToolButton: {
    backgroundColor: '#3498db',
  },
  toolButtonText: {
    color: '#ecf0f1',
    fontWeight: '500',
  },
  activeToolButtonText: {
    fontWeight: 'bold',
  },
});

export default ToolBar;
