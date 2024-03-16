import { WebPlugin } from '@capacitor/core';
import type { CameraPreviewOptions, CameraPreviewPictureOptions, CameraPreviewPlugin, CameraPreviewFlashMode, CameraSampleOptions, CameraOpacityOptions, CameraPreviewExposureMode, CameraPreviewWhiteBalanceMode } from './definitions';
export declare class CameraPreviewWeb extends WebPlugin implements CameraPreviewPlugin {
    /**
     *  track which camera is used based on start options
     *  used in capture
     */
    private isBackCamera;
    constructor();
    start(options: CameraPreviewOptions): Promise<{}>;
    startRecordVideo(): Promise<{}>;
    stopRecordVideo(): Promise<{}>;
    getSupportedPictureSizes(): Promise<{
        result: {
            width: number;
            height: number;
        }[];
    }>;
    getExposureModes(): Promise<{
        result: CameraPreviewExposureMode[];
    }>;
    getSupportedWhiteBalanceModes(): Promise<{
        result: CameraPreviewWhiteBalanceMode[];
    }>;
    getExposureCompensationRange(): Promise<{
        result: {
            min: number;
            max: number;
        };
    }>;
    getExposureCompensation(): Promise<{
        result: number;
    }>;
    getExposureMode(): Promise<{
        result: CameraPreviewExposureMode;
    }>;
    setExposureMode(_options: {
        exposureMode: CameraPreviewExposureMode | string;
    }): Promise<void>;
    setExposureCompensation(_options: {
        exposureCompensation: number;
    }): Promise<void>;
    setWhiteBalanceMode(_options: {
        whiteBalanceMode: CameraPreviewWhiteBalanceMode | string;
    }): Promise<void>;
    getWhiteBalanceMode(): Promise<{
        result: CameraPreviewWhiteBalanceMode;
    }>;
    stop(): Promise<any>;
    capture(options: CameraPreviewPictureOptions): Promise<any>;
    captureSample(_options: CameraSampleOptions): Promise<any>;
    getSupportedFlashModes(): Promise<{
        result: CameraPreviewFlashMode[];
    }>;
    setFlashMode(_options: {
        flashMode: CameraPreviewFlashMode | string;
    }): Promise<void>;
    flip(): Promise<void>;
    setOpacity(_options: CameraOpacityOptions): Promise<any>;
}
