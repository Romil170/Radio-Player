
import UIKit
import MediaPlayer
import AVKit

class NowPlayingViewController: UIViewController {
    

    // MARK: - IB UI
    @IBOutlet var btnPlayingAnimation: UIButton!
    @IBOutlet var VideoView: UIView!
    @IBOutlet var sliderVolum: UISlider!
    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    
    // MARK: - Properties
    var player = AVPlayer()
    var playerItem : AVPlayerItem?
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = FRadioPlayer.shared
    
    var mpVolumeSlider: UISlider?

    override func viewDidLoad() {
        super.viewDidLoad()
        createNowPlayingAnimation()
        play()
    }
    @IBAction func volumChange(_ sender: UISlider) {
        player.volume = sender.value
    }
    @IBAction func btnPlayClick(_ sender: UIButton) {
        player.play()
        startNowPlayingAnimation(true)
      //  radioPlayer.play()
    }
    @IBAction func btnStopClick(_ sender: UIButton) {
        player.pause()
        startNowPlayingAnimation(false)
     //   radioPlayer.stop()
    }
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIView.ContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: .custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        btnPlayingAnimation.addSubview(barButton)
      //  let barItem = UIBarButtonItem(customView: barButton)
      //  self.navigationItem.rightBarButtonItem = barItem
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingImageView.startAnimating() : nowPlayingImageView.stopAnimating()
    }
    func play() {
        if let url = URL(string: "") { // add here your radion url
            let asset = AVAsset(url: url)
            playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.VideoView.bounds
            playerLayer.videoGravity = .resizeAspect
            self.VideoView.layer.addSublayer(playerLayer)
            player.volume = 0.5
            sliderVolum.value = 0.5
            playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
            self.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { (time) in
                if self.player.currentItem?.status == .readyToPlay {
                   // let currentTime = CMTimeGetSeconds(self.player.currentTime())
                    //let secs = Int(currentTime)
                    // self.lbl.text = NSString(format: "%02d:%02d", secs/60, secs%60) as String//"\(secs/60):\(secs%60)"
                }})
            player.play()
            startNowPlayingAnimation(true)
        }
    }
    func shouldGetArtwork(for rawValue: String?, _ enabled: Bool) {
        guard enabled else { return }
        guard let rawValue = rawValue else {
            return
        }
        
        FRadioAPI.getArtwork(for: rawValue, size: 200, completionHandler: { [unowned self] artworlURL in
            DispatchQueue.main.async {
                print("mu url for image.....",artworlURL)
                if artworlURL != nil
                {
                    ImageLoader.sharedLoader.imageForUrl(urlString: artworlURL?.absoluteString ?? "") { (image, stringURL) in
                        self.albumImageView.image = image
                    }
                }
                else
                {
                    self.albumImageView.image = UIImage(named: "No-Image-Available.png")
                }
                
            }
        })
    }
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let item = object as? AVPlayerItem, let keyPath = keyPath, item == self.playerItem {
            
            switch keyPath {
                
          //  case "status":
                
              //  if player?.status == AVPlayer.Status.readyToPlay {
               //     self.state = .readyToPlay
               // } else if player?.status == AVPlayer.Status.failed {
               //     self.state = .error
              //  }
                
            case "playbackBufferEmpty":
                
                if item.isPlaybackBufferEmpty {
                   // self.state = .loading
                    print("buffer empty..........")
                }
                
           // case "playbackLikelyToKeepUp":
                
             //   self.state = item.isPlaybackLikelyToKeepUp ? .loadingFinished : .loading
            
            case "timedMetadata":
                let rawValue = item.timedMetadata?.first?.value as? String
                if rawValue != nil
                {
                    let parts = rawValue?.components(separatedBy: " - ")
                    songLabel.text = parts?.last
                    artistLabel.text = parts?.first
                    print(parts?.first)
                    print(parts?.last)
                    shouldGetArtwork(for: rawValue, true)
                }
                
            default:
                break
            }
        }
    }
}




struct Track {
    var title: String
    var artist: String
    var artworkImage: UIImage?
    var artworkLoaded = false
    
    init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}


struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String
    
    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String = "") {
        self.name = name
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
    }
}

extension RadioStation: Equatable {
    
    static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}
