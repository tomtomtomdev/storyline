# Background Audio Testing Guide

This document outlines how to test the background audio features of the Storyline audiobook player.

## Features Implemented

### 1. Background Playback
- Audio continues playing when app is backgrounded
- Configured audio session with `.playback` category

### 2. Lock Screen Controls
- Audio information displayed on lock screen
- Play/pause/skip controls available
- Progress indicator shows playback position

### 3. Control Center Integration
- Media controls appear in Control Center
- Seek slider for navigating audio
- Speed control button

### 4. Remote Command Center
- Headphone button controls:
  - Single press: Play/Pause
  - Double press: Next track (disabled in current implementation)
  - Triple press: Previous track (disabled in current implementation)
- AirPlay streaming support
- Bluetooth device support

### 5. Audio Interruption Handling
- Automatically pauses for phone calls
- Resumes playback after call ends (if configured)
- Pauses when headphones are unplugged
- Handles system audio interruptions

## Testing Checklist

### Required Equipment
- Physical iPhone or iPad (iOS 17.0+)
- Headphones with playback controls
- (Optional) Bluetooth audio device
- (Optional) AirPlay receiver

### Test Scenarios

#### Basic Playback
- [ ] Load and play an audiobook
- [ ] Verify audio plays correctly
- [ ] Test pause/resume functionality
- [ ] Test skip forward/backward (15 seconds)
- [ ] Test variable speed playback (0.5x to 2.5x)

#### Background Playback
- [ ] Start playing an audiobook
- [ ] Press home button or switch apps
- [ ] Verify audio continues playing
- [ ] Return to app - verify UI shows correct state

#### Lock Screen Controls
- [ ] Start playing an audiobook
- [ ] Lock the device
- [ ] Verify audio controls appear on lock screen
- [ ] Test play/pause button on lock screen
- [ ] Verify artwork and metadata display correctly

#### Control Center
- [ ] Start playing an audiobook
- [ ] Open Control Center
- [ ] Verify media player section appears
- [ ] Test all control buttons
- [ ] Test seek slider functionality
- [ ] Verify time display updates

#### Headphone Controls
- [ ] Connect headphones with playback controls
- [ ] Start playing audiobook
- [ ] Test play/pause with headphone button
- [ ] Test skip forward/backward if supported

#### Bluetooth/AirPlay
- [ ] Connect Bluetooth audio device
- [ ] Verify audio routes to device
- [ ] Test playback controls
- [ ] Test AirPlay streaming (if available)

#### Audio Interruptions
- [ ] Start playing audiobook
- [ ] Receive phone call
- [ ] Verify playback pauses
- [ ] End call
- [ ] Verify playback resumes (if option allows)
- [ ] Unplug headphones during playback
- [ ] Verify playback pauses

#### Multiple Interruptions
- [ ] Test rapid interruption scenarios
- [ ] Verify app remains stable
- [ ] Check audio session recovery

## Device-Specific Considerations

### iPhone
- Test with and without notch
- Verify Dynamic Type support
- Test in different orientations

### iPad
- Test multitasking with Split View
- Verify Slide Over compatibility
- Test in both orientations

## Known Limitations

1. **Simulator Limitations**
   - Background audio may not work properly
   - Lock screen controls not available
   - AirPlay not functional
   - Always test on physical device

2. **First Launch**
   - User must grant audio playback permissions
   - May need to enable in Settings if denied

3. **Battery Optimization**
   - iOS may kill background processes in low battery
   - Users may need to disable "Low Power Mode" for continuous playback

## Troubleshooting

### Audio Not Playing in Background
1. Check device Settings → Battery → Background App Refresh
2. Ensure Storyline is enabled for background refresh
3. Check if Low Power Mode is enabled

### Controls Not Showing
1. Verify app has proper audio entitlements
2. Check if other audio apps are playing
3. Restart the app

### Poor Audio Quality
1. Check network connection for streaming
2. Verify file format support
3. Test with different audio sources

## Performance Metrics

Monitor these during testing:
- Memory usage during background playback
- CPU impact on battery life
- Audio latency
- UI responsiveness during background playback

## Automation

For CI/CD, only basic unit tests can run on simulators. Full background audio testing requires:
- Physical device testing
- Manual verification steps
- Integration testing with actual audio hardware