//
//  AppleEsqueViewController.swift
//
//  Created by Huy Bui on 2022-07-17.
//

import UIKit
import IQKeyboardManagerSwift

class AppleEsqueViewController: UIViewController, UIScrollViewDelegate {
    
    // Strings & values
    private var titleText: String = "Title Text",
                primaryButtonText: String = "Continue",
                secondaryButtonText: String = "Skip"
    
    // Metrics & sizing
    private let fontMetrics = UIFontMetrics(forTextStyle: .body)
    private var screenWidth: CGFloat!,
                screenHeight: CGFloat!,
                topPadding: CGFloat!,
                _extraTopPadding: CGFloat!,
                _titleToContentGap: CGFloat!,
                _contentGap: CGFloat!
    
    // Constraints
    private var mainIconTopIconConstraint: NSLayoutConstraint!,
                containerStackViewWidthConstraint: NSLayoutConstraint!
    
    // Views
    private var scrollView: UIScrollView!,
                mainIcon: UIImageView!,
                titleLabel: UILabel!,
                infoView: UIView!,
                primaryButton: UIButton!,
                primaryButtonVisualEffectView: UIVisualEffectView!,
                secondaryButton: UIButton!,
                containerStackView: UIStackView!,
                textField: UITextField!
    
    // Actions
    private var hasPrimaryButton: Bool = true,
                _primaryButtonAction: UIAction!,
                hasSecondaryButton: Bool = false,
                _secondaryButtonAction: UIAction!,
                dismissAction: UIAction!
    
    
    // MARK: - Initializers -
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(title: String,
         titleToContentGap: CGFloat? = nil, contentGap: CGFloat? = nil, extraTopPadding: CGFloat? = nil, // Metrics
         addPrimaryButton: Bool = true, primaryButtonTitle: String = "Continue", primaryButtonAction: UIAction? = nil, // Primary button
         addSecondaryButton: Bool = false, secondaryButtonTitle: String = "Skip", secondaryButtonAction: UIAction? = nil // Secondary button
    ) {
        super.init(nibName: nil, bundle: nil)
        
        dismissAction = UIAction() {
            [weak self] _ in
            self?.dismiss(animated: true)
        }
//        log("getScreenDimensions().width = \(getScreenDimensions().width)")
//        log("getScreenDimensions().height = \(getScreenDimensions().height)")
        
        // iPad mini 6
        // 744 x 1133 --> titleToContentGap: 56, contentGap: 36
        ///
        // iPhone 13 Pro Max
        // 428 x 925 --> titleToContentGap: 56, contentGap: 36
        
        // iPhone 13 (Pro)
        // 390 x 844 --> titleToConentGap: 56, contentGap: 26
        
        // iPhone 13 mini
        // 375 x 812 --> titleToContentGap: 37, contentGap: 26

        titleText = title
        
        // Metrics
        _titleToContentGap = titleToContentGap ?? (getScreenDimensions().width >= 390 ? 57 : 37) // Screen wider than iPhone 13 Pro, 56, else, 37
        _contentGap = contentGap ?? (getScreenDimensions().width >= 428 ? 36 : 26) // Screen wider than iPhone 13 Pro Max, 36, else, 26
        _extraTopPadding = extraTopPadding ?? 0
        
        // Primary button
        hasPrimaryButton = addPrimaryButton
        primaryButtonText = primaryButtonTitle
        _primaryButtonAction = primaryButtonAction ?? dismissAction
        
        // Secondary button
        hasSecondaryButton = addSecondaryButton
        secondaryButtonText = secondaryButtonTitle
        _secondaryButtonAction = secondaryButtonAction ?? dismissAction
        
        loadView()
        viewDidLoad()
    }
    
    // MARK: - Function overrides -
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        self.modalPresentationStyle = .formSheet
//        self.navigationController?.modalPresentationStyle = .formSheet // Doesn't work; must set manually before presenting if embedded inside a navigation controller
        
        screenWidth = getScreenDimensions().width
        screenHeight = getScreenDimensions().height
        
        mainIcon = UIImageView()
        mainIcon.translatesAutoresizingMaskIntoConstraints = false
        mainIcon.contentMode = .scaleAspectFit
        
        // MARK: Title label configs
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.text = titleText
        
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        // MARK: Container stack view configs
        
        containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .vertical
        containerStackView.spacing = _contentGap
        
        // MARK: Primary button configs
        
        primaryButton = UIButton(primaryAction: _primaryButtonAction)
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.configuration = UIButton.Configuration.filled()
        
        // Font & text
        primaryButton.configuration?.attributedTitle = AttributedString(primaryButtonText)
        primaryButton.configuration?.attributedTitle?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // Appearance
//        primaryButton.tintColor = .systemBlue
        primaryButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        primaryButton.configuration?.cornerStyle = .fixed
        primaryButton.configuration?.background.cornerRadius = 14
        
        primaryButtonVisualEffectView = UIVisualEffectView(effect: .none)
        primaryButtonVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: Secondary button configs
        secondaryButton = UIButton(primaryAction: _secondaryButtonAction)
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        secondaryButton.configuration = .plain()
        
        secondaryButton.configuration?.attributedTitle = AttributedString(secondaryButtonText)
        secondaryButton.configuration?.attributedTitle?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // MARK: Scroll view configs
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        scrollView.addSubview(mainIcon)
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(containerStackView)
        scrollView.addSubview(primaryButtonVisualEffectView)
        
        view.addSubview(scrollView)
        
        // Calculating metrics
        topPadding = screenWidth > 700 ? 64 : getScreenDimensions().height/11
        let primaryButtonWidth = min(screenWidth/1.146788990825688, 340)
        let stackViewPadding = screenWidth == 428 ? 100 : screenWidth / 6.25 // iPhone 13 Pro Max, 100, else use formula
        
        if hasPrimaryButton {
            let _topPadding: CGFloat = screenWidth <= 375 ? 5 : 30
            primaryButtonVisualEffectView.contentView.addSubview(primaryButton)
            
            NSLayoutConstraint.activate([
                primaryButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -55),
                primaryButton.widthAnchor.constraint(equalToConstant: primaryButtonWidth),
                primaryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                // Constraints for blur view
                primaryButtonVisualEffectView.widthAnchor.constraint(equalTo: view.widthAnchor),
                primaryButtonVisualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                primaryButtonVisualEffectView.topAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -(_topPadding)),
            ])
        }
        
        if hasSecondaryButton {
            scrollView.addSubview(secondaryButton)
            NSLayoutConstraint.activate([
                secondaryButton.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
                secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 12)
            ])
        }
        
        // MARK: Constraints
        
        // Constraint properties that can be changed later
        mainIconTopIconConstraint = mainIcon.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: topPadding - 15 + _extraTopPadding)
        containerStackViewWidthConstraint = containerStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -(stackViewPadding))

        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding - 15),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            mainIcon.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: _extraTopPadding),
//            mainIcon.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: topPadding - 15 + _extraTopPadding),
            mainIconTopIconConstraint,
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: mainIcon.bottomAnchor, constant: 15),
            titleLabel.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -(screenWidth / 6.25)),

            containerStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: _titleToContentGap),
            containerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            containerStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -(stackViewPadding))
            containerStackViewWidthConstraint
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTopPadding), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        containerStackView.layoutIfNeeded()
        scrollView.layoutIfNeeded()
        
        let width = self.view.frame.width
        var height = topPadding + _extraTopPadding + mainIcon.frame.height + titleLabel.frame.height + _titleToContentGap + containerStackView.frame.height + primaryButtonVisualEffectView.frame.height
//        height -= view.safeAreaInsets.bottom
//        height -= 9.484848484848
//        scrollView.frame.size.height -= view.safeAreaInsets.bottom
        
        scrollView.contentSize = CGSize(width: width, height: height)
        scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: primaryButtonVisualEffectView.frame.height - view.safeAreaInsets.bottom, right: 0)
        
        // If scrollView's content is taller than scrollView (scrolling enabled)
        if scrollView.contentSize.height > scrollView.frame.size.height {
            primaryButtonVisualEffectView.effect = UIBlurEffect(style: .systemMaterial)
        } else {
            primaryButtonVisualEffectView.effect = .none
        }
    }
    
    // MARK: - Public functions -
    
    func addMainIcon(_ icon: UIImage, withCustomTopPadding _topPadding: CGFloat? = nil) {
        mainIcon.image = icon

        if _topPadding != nil {
            mainIcon.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: topPadding - 15 + _extraTopPadding).isActive = false
            mainIcon.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: _topPadding!).isActive = true
        }
    }
    
    func setTitle(_ text: String) {
        titleLabel.text = text
    }
    
    func disableSwipeDownToDismiss() {
        self.isModalInPresentation = true
        self.navigationController?.isModalInPresentation = true
    }
    
    // MARK: Primary button functions
    
    func setPrimaryButtonTitle(_ text: String) {
        primaryButton.configuration?.attributedTitle = AttributedString(text)
    }
    
    func setPrimaryButtonAction(_ action: UIAction) {
        primaryButton.removeAction(dismissAction, for: .primaryActionTriggered)
        primaryButton.addAction(action, for: .primaryActionTriggered)
    }
    
    // MARK: Secondary button functions
    
    func setSecondaryButtonTitle(_ text: String) {
        secondaryButton.configuration?.attributedTitle = AttributedString(text)
        secondaryButton.configuration?.attributedTitle?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    func setSecondaryButtonImage(_ image: UIImage? = UIImage(systemName: "gear.badge.questionmark"),
                                 placement: NSDirectionalRectEdge = .trailing,
                                 padding: CGFloat = 3) {
        secondaryButton.setImage(image, for: .normal)
        secondaryButton.configuration?.imagePlacement = placement
        secondaryButton.configuration?.imagePadding = padding
    }
    
    func setSecondaryButtonAction(_ action: UIAction) {
        secondaryButton.removeAction(dismissAction, for: .primaryActionTriggered)
        secondaryButton.addAction(action, for: .primaryActionTriggered)
    }
    
    // MARK: Additional components functions
    
    func addInfoView(title: String = "Title", subtitle: String = "The quick brown fox jumps over the lazy dog.", icon: UIImage? = UIImage()) {
        let infoView = getInfoView(title: title, subtitle: subtitle, icon: icon)
        containerStackView.addArrangedSubview(infoView)
    }
    
    func addDescription(_ text: String = "The quick brown fox jumps over the lazy dog.") {
        let description = UILabel()
        description.translatesAutoresizingMaskIntoConstraints = false
        description.text = text
        
        description.lineBreakMode = .byWordWrapping
        description.numberOfLines = 0
        description.setLineHeight(2)
        description.textAlignment = .center
        
        containerStackView.addArrangedSubview(description)
    }
    
    func addTextField(placeholder: String = "e.g. Hello, World!") {
        textField = UITextField2()
        textField.translatesAutoresizingMaskIntoConstraints = false;
        textField.backgroundColor = .systemGray5
        textField.layer.cornerRadius = 10
        textField.placeholder = placeholder
        textField.becomeFirstResponder()
        textField.autocorrectionType = .no
        containerStackView.addArrangedSubview(textField)
    }
    
    func getTextFieldText() -> String? {
        return textField.text
    }
    
    func setTextFieldAutocapitalizationType(_ type: UITextAutocapitalizationType = .none) {
        textField.autocapitalizationType = type
    }
    
    func enableAutocorrection() {
        textField.autocorrectionType = .yes
    }
    
    // MARK: - Private functions -
    
    private func getInfoView(title: String, subtitle: String, icon: UIImage?) -> UIView {
        let infoTitleLabel = UILabel()
        infoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        infoTitleLabel.text = title
//        infoTitleLabel.font = fontMetrics.scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .semibold))
//        infoTitleLabel.adjustsFontForContentSizeCategory = true
        
        let infoSubtitleLabel = UILabel()
        infoSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoSubtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        infoSubtitleLabel.text = subtitle
//        infoSubtitleLabel.font = fontMetrics.scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .regular))
//        infoSubtitleLabel.adjustsFontForContentSizeCategory = true
        
        infoSubtitleLabel.lineBreakMode = .byWordWrapping
        infoSubtitleLabel.numberOfLines = 0
        infoSubtitleLabel.setLineHeight(2)
        infoSubtitleLabel.textColor = .systemGray
        
        let infoIconImageView = UIImageView(image: icon!)
        infoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        infoIconImageView.contentMode = .scaleAspectFit
        infoIconImageView.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        infoIconImageView.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        
        let infoLabelsStackView = UIStackView(arrangedSubviews: [infoTitleLabel, infoSubtitleLabel])
        infoLabelsStackView.translatesAutoresizingMaskIntoConstraints = false
        infoLabelsStackView.axis = .vertical
        infoLabelsStackView.distribution = .fill
        infoLabelsStackView.spacing = 2
        infoLabelsStackView.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        infoLabelsStackView.setContentCompressionResistancePriority(UILayoutPriority(1), for: .horizontal)
        
        let infoView = UIStackView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.axis = .horizontal
        infoView.spacing = 8
        infoView.addArrangedSubview(infoIconImageView)
        infoView.addArrangedSubview(infoLabelsStackView)
        
        NSLayoutConstraint.activate([
            infoIconImageView.widthAnchor.constraint(equalToConstant: 50),
//            infoLabelsStackView.widthAnchor.constraint(equalToConstant: getScreenDimensions().width / 1.8),
        ])
        
        return infoView
    }
    
    private func log(_ item: Any) {
        print("[log]: \(item)")
    }
    
    private func getScreenDimensions() -> CGSize {
        var width = UIScreen.main.bounds.width,
            height = UIScreen.main.bounds.height
        
        if width > height {
            width = height
            height = UIScreen.main.bounds.width
        }
        
        return CGSize(width: width, height: height)
    }
    
    @objc private func setTopPadding() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch UIDevice.current.orientation {
            case .landscapeLeft, .landscapeRight:
//                log("Landscape")
                mainIconTopIconConstraint.constant = topPadding - 50 + _extraTopPadding
                if screenWidth < 428 { // Smaller than iPhone 13 Pro Max
                    containerStackViewWidthConstraint.constant = -(screenWidth / 2)
                }
            case .portrait, .portraitUpsideDown:
//                log("Portrait")
                mainIconTopIconConstraint.constant = topPadding - 15 + _extraTopPadding
                if screenWidth < 428 { // Smaller than iPhone 13 Pro Max
                    containerStackViewWidthConstraint.constant = -(screenWidth / 6.25)
                }
            case .faceUp, .faceDown:
//                log("Flat")
                fallthrough
            case .unknown: fallthrough
            default: doNothing()
            }
        }
    }
    
    private func doNothing() {}
    
    // MARK: - Experimental
    
    @objc private func preferredContentSizeChanged(_ notification: Notification) {
        log(traitCollection.preferredContentSizeCategory.rawValue)
        
//        switch contentSizeCategory {
//        case "XS", "S", "M", "L", "XL":
//        default:
//        }
    }
    
    func scrollViewDidScroll(_ _scrollView: UIScrollView) {
        if scrollView.contentSize.height > scrollView.frame.size.height {
            if (scrollView.contentOffset.y.rounded(.down) >= (scrollView.contentSize.height - scrollView.frame.size.height + view.safeAreaInsets.bottom).rounded(.down)) { // Reached bottom
                if primaryButtonVisualEffectView.effect != .none {
                    primaryButtonVisualEffectView.effect = .none
                }
            } else {
                if primaryButtonVisualEffectView.effect != UIBlurEffect(style: .systemMaterial) {
                    primaryButtonVisualEffectView.effect = UIBlurEffect(style: .systemMaterial)
                }
            }
        }

//        log("scrollView.contentOffset.y = \(scrollView.contentOffset.y)")
//        if scrollView1.contentOffset.y > titleLabel.frame.height - (navigationController?.navigationBar.frame.height)! {
//            hiddenTitle(false)
//
//            UIView.animate(withDuration: 1, animations: {
//                [weak self] in
//                self?.navigationController?.navigationBar.alpha = 1
//                self?.title = "Test"
//                self?.navigationItem.titleView?.alpha = 1
//            })
//        } else {
//            hiddenTitle(true)
//
//            UIView.animate(withDuration: 1, animations: {
//                [weak self] in
//                self?.navigationController?.navigationBar.alpha = 0
//                self?.title = ""
//                self?.navigationItem.titleView?.alpha = 0
//            })
//        }
    }
    
    private func hiddenTitle(_ hidden: Bool) {
        let animation = CATransition()
            animation.duration = 2
            animation.type = .fade
        
        navigationController?.navigationBar.layer.add(animation, forKey: "fadeText")

        if hidden {
            navigationItem.title = ""
        } else {
            navigationItem.title = "Welcome to People"
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Extensions & custom classes -

extension UILabel {
    func setLineHeight(_ lineHeight: CGFloat) {
        guard let text = self.text else { return }
        
        let attributedString = NSMutableAttributedString(string: text)
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineHeight
        
        attributedString.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: style,
            range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}

class UITextField2: UITextField {
    let padding = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10);

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

