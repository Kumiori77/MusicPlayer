//
//  ViewController.swift
//  MusicPlayer
//
//  Created by 이재언 on 2023/01/11.
//
//
import UIKit
import AVFoundation // 앱에서 미디어 처리 및 제어를 위해 임포트

// AVAudioPlayerDelegate 프로토콜을 추가로 준수 -> 미디어의 변화를 감지하는 콜백 메소드를 제공하는 프로퍼티
class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    // MARK: - 프로퍼티
    var player: AVAudioPlayer! // 메모리나 파일에 있는 사운드 데이터 재생하는 클래스
    var timer: Timer! // 일정한 시간 간격이 지나면 지정된 메시지를 특정 객체로 전달하는 클래스
    
    // 인터페이스 프로퍼티
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var progressSlider: UISlider!
    
    // MARK: - 메소드

    // UIViewController 클래스에서 상속받아 재정의하는 메소드. 뷰 컨트롤러의 뷰가 메모리에 로드된 후에 호출
    // 재정의 해서 뷰가 로드된 이후에 실행할 작업 구현
    override func viewDidLoad() {
        // 부모 클래스의 메소드 호출
        super.viewDidLoad()
        
        // 코드로 인터페이스들 생성
        self.addViewsWidthCode()
        
        // 타이머 생성 메소드 호출
        self.initializePlayer()
    }
    
    // 플래이어 초기화 메소드
    func initializePlayer() {
        // 에셋에서 해당 이름의 데이터의 참조를 얻어와서 NSDataAsset 클래스의 인스턴스 생성
        // NSDataAsset : 앱 내에 포함된 데이터를 가져오는 클래스
        guard let soundAsset: NSDataAsset = NSDataAsset(name: "sound") else {
            print("재생할 음원이 없음")
            return
        }
        do { // 에러 감지
            // 메모리의 데이터를 이용해서 AVAudioPlayer 클래스의 인스턴스 생성
            // 위에서 생성한 soundAsset의 data 프로퍼티를 전달
            try self.player = AVAudioPlayer(data: soundAsset.data)
            
            // delegate 프로퍼티 : AVAudioPlayerDelegate 프로토콜을 채택한 객체
            // 오디오 플레이어의 상태변화를 감지할 수 있는 콜백 메소드를 제공
            self.player.delegate = self
            
        } catch let error as NSError { // 에러 처리
            print("플레이어 초기화 실패")
            print("코드 : \(error.code), 메세지 : \(error.localizedDescription)")
        }
        
        // 슬라이더의 최대값을 사운드의 총 재생 시간(duration)으로 지정
        self.progressSlider.maximumValue = Float(self.player.duration)
        self.progressSlider.minimumValue = 0 // 슬라이더의 최소값을 0으로 지정
        // 슬라이더의 현재값을 플래이어의 현재 재생 시각(currentTime)으로 지정
        self.progressSlider.value = Float(self.player.currentTime)
    }
    
    // 레이블을 업데이트 하는 메소드
    func updateTimeLabelText(time: TimeInterval) { // 시간 데이터를 매개변수로 받음(초단위)
        let minute: Int = Int(time / 60) // 분
        let second: Int = Int(time.truncatingRemainder(dividingBy: 60)) // 초
        let milisecond: Int = Int(time.truncatingRemainder(dividingBy: 1) * 100) // 밀리초
        // truncatingRemainder(dividingBy:) : 부동소수점 타입의 나머지 연산을 수행해 주는 함수
        
        // 형식에 맞게 변환
        let timeText: String = String(format: "%02ld:%02ld:%02ld", minute, second, milisecond)
        // 02 : 정수 2자리, 남는 자리는 0으로 채우기, ld : long 타입
        
        // 라벨의 텍스트를 (text 프로퍼티) 위에서 포맷으로 정리한 문자열로 지정
        self.timeLabel.text = timeText
    }
    
    // 타이머 만들고 수행할 메소드 - 0.01초 마다 레이블과 슬라이더를 플래이시간으로 업데이트
    func makeAndFireTimer() {
        // scheduledTimer() : Timer 클래스의 타입 메소드. 지정된 시간마다 지정된 코드를 실행하는 타이머 생성
        // (실행되는 간격, 반복 여부, 실행할 코드)
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {
            // [unowned self] 는 클로저 안에서 self 키워드를 사용해서 인스턴스 자신에 접근하도록 해줌
            [unowned self] (timer: Timer) in
            if self.progressSlider.isTracking { return }
            // 슬라이더를 움직이고 있으면 타이머 동작 안함
            
            // 레이블을 업데이트 하는 인스턴스 메소드에 플래이어의 현제 재생 시각(currentTime)을 넘겨줘서 호출
            self.updateTimeLabelText(time: self.player.currentTime)
            // 슬라이더의 위치를 플래에어의 현재 시간으로 지정
            self.progressSlider.value = Float(self.player.currentTime)
            
        })
    }
    
    // 타이머 해제 메소드
    func invalidateTimer() {
        self.timer?.invalidate() // 타이머 종료 메소드
        self.timer = nil
    }
    
    
    // MARK: - 코드로 화면 그리기
    // 뷰에 요소들을 추가하는 메소드
    func addViewsWidthCode() {
        self.addPlayPauseButton()
        self.addTimeLabel()
        self.addProgressSlider()
    }
    
    // 플래이 버튼을 정의하는 메소드
    func addPlayPauseButton() {
        // 버튼 인스턴스 생성(타입은 custom)
        let button: UIButton = UIButton(type: UIButton.ButtonType.custom)
        // 오토 레이이아웃 적용 위해 오토리사이징마스크 false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 뷰에 서브 뷰로 버튼 추가
        self.view.addSubview(button)
        
        // 상황별 버튼의 이미지 설정
        button.setImage(UIImage(named: "button_play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "button_pause"), for: UIControl.State.selected)
        
        // 버튼과 타겟 연결
        // (연결할 뷰, 연결할 메소드, 연결할 이벤트)
        button.addTarget(self, action: #selector(self.touchPlayPauseButton(_:)), for: UIControl.Event.touchUpInside)
        
        // 제약조건 생성
        let centerX: NSLayoutConstraint
        // 버튼의 x센터 앵커를 뷰의 x센터 앵커로 지정
        centerX = button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        let centerY: NSLayoutConstraint
        // 버튼의 y센터 앵커를 뷰의 y센터 앵커로부터 0.8 떨어뜨려서 지정
        centerY = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 0.6, constant: 0)
        
        let width: NSLayoutConstraint
        //  버튼의 가로 길이을 뷰의 가로길이의 0.5배로 지정
        width = button.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3)
        
        let ratio: NSLayoutConstraint
        // 버튼의 세로 길이를 버튼의 가로길이와 동일하게 지정
        ratio = button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1)
        
        // 제약 조건들 활성화
        centerX.isActive = true
        centerY.isActive = true
        width.isActive = true
        ratio.isActive = true
        
        // 클래스의 플레이버튼 인스턴스에 메소드에서 생성하고 정의한 버튼 할당
        self.playPauseButton = button
    }
    
    // 타임 레이블을 정의하는 메소드
    func addTimeLabel() {
        // 타임 레이블 생성
        let timeLabel: UILabel = UILabel()
        // 오토레이아웃 적용을 위해서 리사이징마스크 false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 뷰의 서브 뷰로 타입 레이블 추가
        self.view.addSubview(timeLabel)
        
        // 스타일 설정
        timeLabel.textColor = UIColor.black // 글자색 지정
        timeLabel.textAlignment = NSTextAlignment.center // 가운데 정렬
        // 폰트를 해드라인으로 지정
        timeLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        
        // 제약 조건 생성
        let centerX: NSLayoutConstraint
        // 타임 레이블의 x센터 앵커를 플래이버튼의 x센터 앵커과 동일하게 지정
        centerX = timeLabel.centerXAnchor.constraint(equalTo: self.playPauseButton.centerXAnchor)
        
        let top: NSLayoutConstraint
        // 타임 레이블의 탑 앵커를 플레이 버튼의 바닥 앵커에서 밑으로 8 떨어뜨려 지정
        top = timeLabel.topAnchor.constraint(equalTo: self.playPauseButton.bottomAnchor, constant: 8)
        
        // 제약 조건 활성화
        centerX.isActive = true
        top.isActive = true
        
        // 클래스의 타입 레이블 프로퍼티에 메소드에서 생성한 타입 레이블 할당
        self.timeLabel = timeLabel
        // 타임 레이블의 시간을 0으로 설정
        self.updateTimeLabelText(time: 0)
        
    }
    
    // 슬라이더를 정의하는 메소드
    func addProgressSlider() {
        // 슬라이더 생성
        let slider: UISlider = UISlider()
        // 오토래이아웃 적용을 위헤 리사이징 마스크 false
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // 뷰의 서브뷰에 슬라이더 추가
        self.view.addSubview(slider)
        
        // 슬라이더의 앞쪽 색상 설정
        slider.minimumTrackTintColor = UIColor.red
        
        // 슬라이더와 타겟 연결
        // (연결할 뷰, 연결할 메소드, 연결할 이벤트)
        slider.addTarget(self, action: #selector(self.sliderValueChanged(_:)), for: UIControl.Event.valueChanged)
        
        // 오토 레이아웃 (새이프 애리어) 가이드 생성? (새이프 애리어 가이드를 뷰의 새이프 애리어 가이드로 설정)
        let safeAreaGuide: UILayoutGuide = self.view.safeAreaLayoutGuide
        
        // 제약 조건 생성
        
        let centerX: NSLayoutConstraint
        // 슬라이더의 x센터 앵커를 타임 레이블의 x센터 앵커와 동일하게 설정
        centerX = slider.centerXAnchor.constraint(equalTo: self.timeLabel.centerXAnchor)
        
        let top: NSLayoutConstraint
        // 슬라이더의 탑 앵커를 타임 레이블의 바텀 앵터로 부터 8 아래로 설정
        top = slider.topAnchor.constraint(equalTo: self.timeLabel.bottomAnchor, constant: 8)
        
        let leading: NSLayoutConstraint
        // 슬라이더의 리딩 앵커(왼쪽)를 새이프 애리어의 리딩 앵커로 부터 16 떨어뜨려서 설정
        leading = slider.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 16)
        
        let trailing: NSLayoutConstraint
        // 슬라이더의 트래일링 앵커(오른쪽)를 새이프 애리어의 트래일링 앵커로 부터 -16 떨어뜨려서 설정
        trailing = slider.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -16)
        
        // 제약 조건 활성화
        centerX.isActive = true
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        
        // 클래스의 슬라이더에 메소드에서 생성한 슬라이더를 할당
        self.progressSlider = slider
    }
    
    
    // 재생버튼 메소드
    @IBAction func touchPlayPauseButton(_ sender: UIButton) { // 매개변수 : 어떤 버튼이 보냈는지
        
        // 전송된 버튼의 선택 여부를 반전
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            self.player?.play() // 선택되면 플레이어 재생
            self.makeAndFireTimer() // 선택되면 makeAndFireTimer() 메소드 호출
        }
        else {
            self.player?.pause() // 선택 해제되면 플레이어 정지
            self.invalidateTimer() // 해제되면 타이머 종료 메소드 호출
        }
    }

    // 슬라이더 메소드
    @IBAction func sliderValueChanged(_ sender: UISlider) { // 매개변수 : 어떤 버튼이 보냈는지

        // 메소드를 호출해서 슬라이더의 값으로 레이블의 시간 설정
        self.updateTimeLabelText(time: TimeInterval(sender.value))
        // 슬라이더가 움직이고 있으면 메소드 종료
        if sender.isTracking { return }
        // 플레이어의 현재 시각을 슬라이더의 값으로 지정
        self.player.currentTime = TimeInterval(sender.value)
        
        // 슬라이더를 움직일 때마다 레이블의 시간이 변경되고 슬라이더에서 손을 때면 해당 시간부터 플레이어 재생
    }
    
    //AVAudioPlayerDelegate 프로토콜이 요구하는 콜백 메소드들
    // 이벤트 발생시 피드백 해주는 콜백 메소드
    
    // 에러 발생시 처리 메소드
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
              guard let error: Error = error else {
            print("오디오 플레이어에서 디코드 에러 발생")
            return
        }
        // 에러가 발생했으면
        
        let message: String = "오디오 플레이어 에러 발생 \(error.localizedDescription)"
        // error.localizedDescription : Error의 간단한 에러 설명 문자열
        
        // 알림 대화상자 클래스의 인스턴스 생성
        let alert: UIAlertController = UIAlertController(title: "알림", message: message, preferredStyle: UIAlertController.Style.alert)
        
        // 알림의 버튼 정의 클래스의 인스턴스 생성
        let okAction: UIAlertAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.default) { (action: UIAlertAction) -> Void in
            // 화면에 표시되는 뷰 컨트롤러를 제거하는 메소드
            // (애니메이션 사용 여부, 뷰 컨트롤러 제거후 실행할 클로저)
            self.dismiss(animated: true, completion: nil)
            // => "확인"버튼을 누르면 창을 닫음
        }
        
        alert.addAction(okAction) // 알림 인스턴스에 버튼 인스턴스 추가
        
        // 새로운 뷰 컨트롤러를 현재 화면에 표시(화면에 알림 표시)
        self.present(alert, animated: true, completion: nil)
    }
    
    // 음악이 종료되면 처음으로 돌리는 메소드
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playPauseButton.isSelected = false // 재생 버튼을 선택 안된 것으로
        self.progressSlider.value = 0 // 슬라이드를 처음으로
        self.updateTimeLabelText(time: 0) // 레이블의 시간을 0으로
        self.invalidateTimer() // 타이머 종료
    }
    
}

