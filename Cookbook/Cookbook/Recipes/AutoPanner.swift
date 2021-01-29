import AudioKit
import AVFoundation
import SwiftUI

struct AutoPannerData {
    var frequency: AUValue = 10.0
    var depth: AUValue = 1.0
    var rampDuration: AUValue = 0.02
    var balance: AUValue = 0.5
}

class AutoPannerConductor: ObservableObject, ProcessesPlayerInput {

    let engine = AudioEngine()
    let player = AudioPlayer()
    let panner: AutoPanner
    let dryWetMixer: DryWetMixer
    let playerPlot: NodeOutputPlot
    let pannerPlot: NodeOutputPlot
    let mixPlot: NodeOutputPlot
    let buffer: AVAudioPCMBuffer

    init() {
        buffer = Cookbook.sourceBuffer

        panner = AutoPanner(player)
        dryWetMixer = DryWetMixer(player, panner)
        playerPlot = NodeOutputPlot(player)
        pannerPlot = NodeOutputPlot(panner)
        mixPlot = NodeOutputPlot(dryWetMixer)
        engine.output = dryWetMixer

        Cookbook.setupDryWetMixPlots(playerPlot, pannerPlot, mixPlot)
    }

    @Published var data = AutoPannerData() {
        didSet {
            panner.$frequency.ramp(to: data.frequency, duration: data.rampDuration)
            panner.$depth.ramp(to: data.depth, duration: data.rampDuration)
            dryWetMixer.balance = data.balance
        }
    }

    var testPlayCount = 1
    
    func start() {
        print("Start engine")
        playerPlot.start()
        pannerPlot.start()
        mixPlot.start()

        do { try engine.start() } catch let err { Log(err) }
        
        // Ryan's test
        let url = Bundle.main.url(forResource: "Sounds/closed_hi_hat_F#1", withExtension: "wav")!
        try! player.load(url: url, buffered: false)
        
        player.completionHandler = {
            DispatchQueue.main.async {
                print("Player end: \(self.testPlayCount)")
                self.testPlayCount += 1
            }
        }
        player.play()
        print("Player start: \(self.testPlayCount)")
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
            self.stop()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
                self.start()
            }
        }
    }

    func stop() {
        print("Stop engine")
        engine.stop()
    }
}

struct AutoPannerView: View {
    @ObservedObject var conductor = AutoPannerConductor()

    var body: some View {
        ScrollView {
//            PlayerControls(conductor: conductor)
        }
        .padding()
        .navigationBarTitle(Text("Ryan's Test"))
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct AutoPanner_Previews: PreviewProvider {
    static var previews: some View {
        AutoPannerView()
    }
}
