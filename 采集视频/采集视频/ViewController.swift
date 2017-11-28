//
//  ViewController.swift
//  采集视频
//
//  Created by sia on 2017/11/28.
//  Copyright © 2017年 BR_buren1111. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {
    
    //捕捉会话 或者 捕获会话
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate var videoOutpu : AVCaptureVideoDataOutput?
    fileprivate var videoInout : AVCaptureDeviceInput?
    fileprivate var previewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var movieOutput : AVCaptureMovieFileOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        //初始化
        //  1初始化视频输入和输出
        setupVideoInputOutout()
        
        //  2初始化音频的输入&输出
        setupAudioInputOutout()
        
        //  3预览图层
        setupPreviewLayer()
        
    }


}

// MARK: - 采集控制
extension ViewController {
    @IBAction func startCaptuer(_ sender: UIButton) {
        
        session.startRunning()
        
//        setupPreviewLayer()
        previewLayer?.isHidden = false
        
        //录制写入文件
        self.setupMoveFileOutput()
    }
    
    @IBAction func stopCaptuer(_ sender: UIButton) {
        //先停止输入
        movieOutput?.stopRecording()
        
        session.stopRunning()
        
        previewLayer?.isHidden = true
    }
    
    @IBAction func changeCamera(_ sender: UIButton) {
        //取出之前镜头的方向
        guard let videoInput = videoInout else { return }
        let postion : AVCaptureDevice.Position = videoInput.device.position == .front ? .back : .front
        
        let devices = AVCaptureDevice.devices()
        guard let device =  devices.filter({ $0.position == postion }).first else { return }
        guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //移除之前的Input 添加新的Input
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(newInput){
            session.addInput(newInput)
        }
        session.commitConfiguration()
        
        //保存最新的Input
        self.videoInout = newInput
    }
}


extension ViewController {
    fileprivate func setupVideoInputOutout(){
        //添加视频的输入
        
        /*
         let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    */
        
        let devices = AVCaptureDevice.devices()
        guard let device =  devices.filter({ $0.position == .back }).first else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInout = input
        
        //添加视频的输出
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        self.videoOutpu = output
        
        //添加输入&输出
        addInputAndOutpuSession(input, output)
    }
    
    
    
    fileprivate func setupAudioInputOutout(){
        
        //创建输入
        guard let device = AVCaptureDevice.default(for: .audio) else { return }
        guard let input = try?  AVCaptureDeviceInput(device: device) else { return }
        
        //创建输出
        let output = AVCaptureAudioDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        
        //添加输入&输出
        addInputAndOutpuSession(input, output)
    }
    
    //添加 输入 输出
    private func addInputAndOutpuSession(_ input : AVCaptureInput, _ output : AVCaptureOutput){
        //添加输入 & 输出
        session.beginConfiguration()
        if session.canAddInput(input){
            session.addInput(input)
        }
        if session.canAddOutput(output){
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
    
    //写入文件
    fileprivate func setupMoveFileOutput(){
        
        if (self.movieOutput != nil) {
            session.removeOutput(movieOutput!)
        }
        
        
        
        //1创建写入文件的输出
        let fileOutput = AVCaptureMovieFileOutput()
        self.movieOutput = fileOutput
        
        //必须设置
        let connection = fileOutput.connection(with: AVMediaType.video)
        connection?.automaticallyAdjustsVideoMirroring = true
        if session.canAddOutput(fileOutput) {
            session.addOutput(fileOutput)
        }
        
        //2直接开始写入文件
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let fileURL = URL(fileURLWithPath: filePath)
        fileOutput.startRecording(to: fileURL, recordingDelegate: self)
        
    }
    
    fileprivate func setupPreviewLayer (){
        //1 创建预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        //2设置 preview属性
        previewLayer?.frame = view.bounds
        //3将图层添加到控制器的View的Layer 中
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        
    }
}
// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate -- AVCaptureAudioDataOutputSampleBufferDelegate 同一个方法
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if videoOutpu?.connection(with: .video) == connection {
            print("采集到一针画面\(Thread.current)")
            
        }else {
            print("音频数据")
        }
    }
}

extension ViewController : AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入文件\(Thread.current)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("完成写入文件\(Thread.current)")
    }
    
    
}




