import type { PermissionState } from '@capacitor/core';

export type CameraPosition = 'rear' | 'front';
export type CameraPreviewExposureMode = 'lock' | 'auto' | 'continuous' | 'custom';
export type CameraPreviewWhiteBalanceMode = 'lock' | 'auto'  | 'continuous' | 'incandescent' | 'cloudy-daylight' | 'daylight' | 'fluorescent' | 'shade' | 'twilight' | 'warm-fluorescent';
export interface CameraPreviewOptions {
  /** Parent element to attach the video preview element to (applicable to the web platform only) */
  parent?: string;
  /** Class name to add to the video preview element (applicable to the web platform only) */
  className?: string;
  /** The preview width in pixels, default window.screen.width */
  width?: number;
  /** The preview height in pixels, default window.screen.height */
  height?: number;
  /** The x origin, default 0 (applicable to the android and ios platforms only) */
  x?: number;
  /** The y origin, default 0 (applicable to the android and ios platforms only) */
  y?: number;
  /**  Brings your html in front of your preview, default false (applicable to the android only) */
  toBack?: boolean;
  /** The preview bottom padding in pixes. Useful to keep the appropriate preview sizes when orientation changes (applicable to the android and ios platforms only) */
  paddingBottom?: number;
  /** Rotate preview when orientation changes (applicable to the ios platforms only; default value is true) */
  rotateWhenOrientationChanged?: boolean;
  /** Choose the camera to use 'front' or 'rear', default 'front' */
  position?: CameraPosition | string;
  /** Defaults to false - Capture images to a file and return the file path instead of returning base64 encoded data */
  storeToFile?: boolean;
  /** Defaults to false - Android Only - Disable automatic rotation of the image, and let the browser deal with it (keep reading on how to achieve it) */
  disableExifHeaderStripping?: boolean;
  /** Defaults to false - iOS only - Activate high resolution image capture so that output images are from the highest resolution possible on the device **/
  enableHighResolution?: boolean;
  /** Defaults to false - Web only - Disables audio stream to prevent permission requests and output switching */
  disableAudio?: boolean;
  /**  Android Only - Locks device orientation when camera is showing. */
  lockAndroidOrientation?: boolean;
  /** Defaults to false - Android and Web only.  Set if camera preview can change opacity. */
  enableOpacity?: boolean;
  /** Defaults to false - Android and iOS only.  Set if camera preview will support pinch to zoom. */
  enableZoom?: boolean;
}
export interface CameraPreviewPictureOptions {
  /** The picture height, respecting the default aspect ratio of the device - Android only */
  height?: number;
  /** The picture width, respecting the default aspect ratio of the device - Android only */
  width?: number;
  /**
   * The picture quality, 0 - 100, default 85 on `iOS/Android`.
   * If left undefined, the `web` implementation will export a PNG, otherwise a JPEG will be generated
   */
  quality?: number;
}

export interface CameraSampleOptions {
  /** The picture quality, 0 - 100, default 85 */
  quality?: number;
}

export type CameraPreviewFlashMode = 'off' | 'on' | 'auto' | 'red-eye' | 'torch';

export interface CameraOpacityOptions {
  /** The percent opacity to set for camera view, default 1 */
  opacity?: number;
}

export interface CameraPreviewPlugin {
  /** Starts the camera preview instance */
  start(options: CameraPreviewOptions): Promise<{}>;
  /** Stops the camera preview instance */
  stop(): Promise<{}>;
  /** Captures a picture from the camera preview */
  capture(options: CameraPreviewPictureOptions): Promise<{ value: string }>;
  /** Captures a sample image from the video stream - Android / iOS only */
  captureSample(options: CameraSampleOptions): Promise<{ value: string }>;
  getSupportedFlashModes(): Promise<{
    result: CameraPreviewFlashMode[];
  }>;
  getSupportedPictureSizes(): Promise<{
    result: { width: number; height: number }[];
  }>;
  getExposureModes(): Promise<{
    result: CameraPreviewExposureMode[];
  }>;
  getSupportedWhiteBalanceModes(): Promise<{
    result: CameraPreviewWhiteBalanceMode[];
  }>;
  getExposureCompensationRange(): Promise<{
    result: { min: number; max: number };
  }>;
  getExposureCompensation(): Promise<{
    result: number;
  }>;
  getExposureMode(): Promise<{
    result: CameraPreviewExposureMode;
  }>;
  getWhiteBalanceMode(): Promise<{
    result: CameraPreviewWhiteBalanceMode;
  }>;
  setFlashMode(options: { flashMode: CameraPreviewFlashMode | string }): Promise<void>;
  setExposureMode(options: { exposureMode: CameraPreviewExposureMode | string }): Promise<void>;
  setExposureCompensation(options: { exposureCompensation: number }): Promise<void>;
  setWhiteBalanceMode(options: { whiteBalanceMode: CameraPreviewWhiteBalanceMode | string }): Promise<void>;
  /** Get the flash modes supported by the camera device currently started */
  getSupportedFlashModes(): Promise<{ result: CameraPreviewFlashMode[] }>;
  /** Set the flash mode */
  setFlashMode(options: { flashMode: CameraPreviewFlashMode | string }): Promise<void>;
  /** Switch between rear and front camera - Android / iOS only */
  flip(): Promise<void>;
  /** Changes the opacity of the shown camera preview - Android / Web only */
  setOpacity(options: CameraOpacityOptions): Promise<{}>;
  /** Start recording a video from the current camera preview - Android only */
  startRecordVideo(options: CameraPreviewOptions): Promise<{}>;
  /** Stop recording a video from the current camera preview - Android only */
  stopRecordVideo(): Promise<{}>;
  /** Check camera permission */
  checkPermissions(): Promise<PermissionState>;
  /** Request camera permission */
  requestPermissions(): Promise<PermissionState>;
}
