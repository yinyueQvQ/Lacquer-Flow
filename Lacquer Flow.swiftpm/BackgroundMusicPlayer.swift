import SwiftUI
import AVFoundation
import AVKit

// MARK: - 背景音乐管理器
@MainActor
class BackgroundMusicPlayer: ObservableObject {
    static let shared = BackgroundMusicPlayer()
    private var audioPlayer: AVAudioPlayer?
    @Published var isMuted: Bool = false

    func playBackgroundMusic() {
        var soundURL: URL?

        // 方法1: 尝试从 Resources 文件夹加载
        let formats = ["mp3", "m4a", "aac", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "Resources/bgm", withExtension: format) {
                soundURL = url
                print("🔍 找到音乐文件 (Resources): bgm.\(format)")
                break
            }
        }

        // ��法2: 尝试 Bundle 资源
        if soundURL == nil {
            for format in formats {
                if let url = Bundle.main.url(forResource: "bgm", withExtension: format) {
                    soundURL = url
                    print("🔍 找到音乐文件 (Bundle): bgm.\(format)")
                    break
                }
            }
        }

        // 方法3: 尝试 Bundle/Resources 路径
        if soundURL == nil {
            for format in formats {
                let path = Bundle.main.bundlePath + "/Resources/bgm.\(format)"
                if FileManager.default.fileExists(atPath: path) {
                    soundURL = URL(fileURLWithPath: path)
                    print("🔍 找到音乐文件 (Bundle/Resources): \(path)")
                    break
                }
            }
        }

        // 方法4: 尝试 Bundle 根目录
        if soundURL == nil {
            for format in formats {
                let path = Bundle.main.bundlePath + "/bgm.\(format)"
                if FileManager.default.fileExists(atPath: path) {
                    soundURL = URL(fileURLWithPath: path)
                    print("🔍 找到音乐文件 (Bundle根目录): \(path)")
                    break
                }
            }
        }

        guard let url = soundURL else {
            print("⚠️ 未找到BGM文件")
            print("   Bundle路径: \(Bundle.main.bundlePath)")
            // 列出 Bundle 内容帮助调试
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
                print("   Bundle内容: \(contents.prefix(5).joined(separator: ", "))")
            }
            return
        }

        do {
            // 配置音频会话
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // 无限循环
            audioPlayer?.volume = isMuted ? 0.0 : 0.3 // 根据静音状态设置音量
            audioPlayer?.play()
            print("🎵 背景音乐开始播放，音量: 60%")
            print("   音频时长: \(audioPlayer?.duration ?? 0) 秒")
            print("   正在播放: \(audioPlayer?.isPlaying ?? false)")
        } catch {
            print("❌ 音乐播放失败: \(error)")
        }
    }

    func stopMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    func toggleMute() {
        isMuted.toggle()
        audioPlayer?.volume = isMuted ? 0.0 : 0.3
    }
}
