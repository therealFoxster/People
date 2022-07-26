//
//  ViewController.swift
//  People
//
//  Created by Huy Bui on 2022-07-15.
//

import UIKit
import Photos
import LocalAuthentication

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate {

    private var people: [Person] = []
    private var personIndex: Int!
    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    private var photoLibraryAuthorizationStatus: PHAuthorizationStatus!
    
    private var isLocked = true
    private let lockedMessage = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = appName
        navigationController?.navigationBar.prefersLargeTitles = true
        
//        (collectionViewLayout as! UICollectionViewFlowLayout).sectionInsetReference = .fromSafeArea
        
        let upcomingFeaturesButton = UIBarButtonItem(image: UIImage(systemName: "star.leadinghalf.filled"), style: .plain, target: self, action: #selector(showUpcomingFeaturesScreen))
        navigationItem.leftBarButtonItem = upcomingFeaturesButton
        
        // Authentication
        let lockButton = UIBarButtonItem(image: UIImage(systemName: "lock"), style: .plain, target: self, action: #selector(toggleLock))
        navigationItem.rightBarButtonItem = lockButton
        
        let lockedTitleLabel = UILabel()
        lockedTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        lockedTitleLabel.text = "Content Locked"
        lockedTitleLabel.textAlignment = .center
        lockedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let lockedSubtitleLabel = UILabel()
        lockedSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lockedSubtitleLabel.text = "Tap the lock icon to unlock and view content."
        lockedSubtitleLabel.textColor = .systemGray
        lockedSubtitleLabel.textAlignment = .center
        lockedSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        lockedMessage.axis = .vertical
        lockedMessage.addArrangedSubview(lockedTitleLabel)
        lockedMessage.addArrangedSubview(lockedSubtitleLabel)
        lockedMessage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lockedMessage)
        NSLayoutConstraint.activate([
            lockedMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockedMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Checks photo library authorization in the background using the utility queue
        DispatchQueue.global(qos: .utility).async {
            self.photoLibraryAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        }
        
        DispatchQueue.main.async {
            // Present in main async to prevent detached view controller warning
            self.showLaunchScreen()
        }
    }
    
    // MARK: - UICollectionView functions -
    
    // numberOfItemsInSection
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    // cellForItemAt
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonUICollectionViewCell else {
            // Failed to dequeue PersonCell
            fatalError("Unable to dequeue PersonCell.")
        }
        
        let person = people[indexPath.item]
        cell.label.text = person.name
        
        // Default imageView configuration for all cells (will be customized later on depending on cell type)
        cell.imageView.layer.cornerRadius = 10
        cell.layer.cornerRadius = 15
        cell.imageView.backgroundColor = .none
        cell.imageView.contentMode = .scaleAspectFit

        if let image = person.image {
            // Add person button
            if image.hasPrefix("SystemImage") {
                let iconName = image.split(separator: Character(":"))[1]
                let addPersonIcon = UIImage(systemName: String(iconName), withConfiguration: UIImage.SymbolConfiguration(pointSize: 48))
                cell.imageView.image = addPersonIcon
                
                cell.imageView.contentMode = .center
            }
            
            // Placeholder person cell
            else if image.hasPrefix("PlaceholderProfilePhoto") {
                cell.imageView.image = UIImage(named: image)
                cell.imageView.contentMode = .scaleAspectFill
            }
            
            // Normal cell (user-added)
            else {
                let imagePath = getDocumentsDirectory().appending(path: image)
                cell.imageView.image = UIImage(contentsOfFile: imagePath.path())
            }
        }
        
        // Cell with no image
        else {
            // Must set imageView.image otherwise the previous image (from previous cells) might get used/recycled
//            cell.imageView.image = nil
            cell.imageView.image = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))?.withTintColor(.systemGray2, renderingMode: .alwaysOriginal)
            
            cell.imageView.backgroundColor = .systemGray5
            cell.imageView.contentMode = .center
        }
        
        // Cell dimensions and component sizing
        let cellDimensions = calculateCellDimensions(),
            imageViewSize = cellDimensions.width - 10 * 2 // 10 * 2 for left & right section insets (set in Main.storyboard)
        cell.imageView.frame.size = CGSize(width: imageViewSize, height: imageViewSize)
        cell.label.frame.size = CGSize(width: imageViewSize, // Same width as imageView
                                       height: cellDimensions.width * 2 + 40 - 10) // cellDimensions.width * 2 shifts label's text vertically to the bottom of imageView, + 40 for label height, - 10 for top inset
        
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress)))
        
        return cell
    }
    
    //  sizeForItemAt
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellDimensions = calculateCellDimensions()
        return CGSize(width: cellDimensions.width, height: cellDimensions.height)
    }
    
    // didSelectItemAt
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
        // Animation on select
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            cell?.alpha = 0.9
            cell?.transform = CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97)
        }, completion: { _ in
            if !(cell?.isHighlighted)! {
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
                    cell?.alpha = 1.0
                    cell?.transform = CGAffineTransform.identity
                })
            }
        })
        
        if indexPath.item == 0 { // Add button; enable select (the rest of the cells must be activated using long press)
            showOptionsForCellAt(indexPath)
        }
    }
    
    func showOptionsForCellAt(_ indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath)
        
        if indexPath.item == 0 { // Add person button
            showAddPersonScreen()
        } else { // Person cell
            let person = people[indexPath.item]

            let alertController = UIAlertController(title: "Configure \"\(person.name)\"", message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceView = cell // For iPads
            
            // Cancel
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Rename
            alertController.addAction(UIAlertAction(title: "Rename", style: .default) {
                [weak self] _ in
                self?.showRenamePersonScreen(forPerson: person)
            })
            
            // Edit/add photo
            let photoAction = person.image != nil ? "Select New" : "Add"
            alertController.addAction(UIAlertAction(title: "\(photoAction) Photo", style: .default) {
                [weak self] _ in
                self?.personIndex = indexPath.item
                self?.showImagePicker(fromViewController: self!)
            })
            
            // Delete
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) {
                [weak self] _ in
                let deleteAlertController = UIAlertController(title: "Delete \"\(person.name)\"?", message: "This action can't be undone.", preferredStyle: .alert)
                deleteAlertController.addAction(UIAlertAction(title: "Cancel", style: .default))
                deleteAlertController.addAction(UIAlertAction(title: "Delete", style: .destructive) {
                    _ in
                    self?.collectionView.performBatchUpdates({
                        self?.people.remove(at: indexPath.item)
                        self?.save()
                        self?.collectionView.deleteItems(at: [indexPath])
                    })
                })
                self?.present(deleteAlertController, animated: true)
            })
            
            present(alertController, animated: true)
        }
    }
    
    func addPlaceholderCells() {
        // Add person button
        people.append(Person(name: "Add", image: "SystemImage:plus"))
        
        // Adding placeholder peole; causes a spike in memory usage with large photos (could be a leak)
        DispatchQueue.global(qos: .default).async {
            for i in 1...7 {
                self.people.append(Person(name: "Person \(i)", image: "PlaceholderProfilePhoto\(i)"))
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: - Image picker functions -
    
    func showImagePicker(fromViewController _viewController: UIViewController) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true // Allows picture cropping
        imagePickerController.delegate = self
        
        // Checking photo library permission
        switch photoLibraryAuthorizationStatus {
        case .authorized:
            _viewController.present(imagePickerController, animated: true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) {
                [weak _viewController] newStatus in
                if newStatus == PHAuthorizationStatus.authorized {
                    DispatchQueue.main.async {
                        _viewController?.present(imagePickerController, animated: true)
                    }
                }
            }
        case .restricted, .limited, .denied, .none:
            let title = "\"\(appName)\" Would Like to Access Your Photos",
                message = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
            
            performActionAfterConfirmation(title: title, message: message!, actionTitle: "Allow Access to All Photos") { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        @unknown default:
            fatalError("Unable to determine user's photo library authorization status.")
        }
    }
    
    // didFinishPickMediaWithInfo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appending(path: imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 1) {
            try? jpegData.write(to: imagePath)
        }
        
        picker.dismiss(animated: true)
        
        if addPersonScreen != nil { // Adding person
            people.insert(person, at: 1)
            people[personIndex].image = imageName
            showAddPersonSuccessScreen(name: person.name) // Doesn't work when updating a person photo because addPersonScreen would not be presented at that time
        } else { // Updating person
            people[personIndex].image = imageName
            collectionView.reloadData()
        }
        save()
    }

    // MARK: - Show screens functions -
    
    func showLaunchScreen() {
        let launchScreen = AppleEsqueViewController(title: "Getting Started in \(appName)")
        
        launchScreen.addInfoView(title: "Names to Faces",
                                 subtitle: "Save names and photos of people you've met so you'll never forget a person ever again! (Hopefully.)",
                                 icon: UIImage(systemName: "person.text.rectangle"))
        launchScreen.addInfoView(title: "More Features in the Work",
                                 subtitle: "This project is a work in progress. View upcoming features by tapping the half-filled star icon at the top right corner of the app.",
                                 icon: UIImage(systemName: "star.leadinghalf.filled"))
        
        launchScreen.disableSwipeDownToDismiss()
        launchScreen.setPrimaryButtonAction(UIAction() { [weak self] _ in
            launchScreen.dismiss(animated: true) {
                self?.toggleLock()
            }
        })
        
        present(launchScreen, animated: true)
    }

    private var addPersonScreen: AppleEsqueViewController!, person: Person!
    func showAddPersonScreen() {
        addPersonScreen =
        AppleEsqueViewController(title: "Enter a Name",
                                 titleToContentGap: getScreenDimensions().height / 60, contentGap: 28, 
                                 addPrimaryButton: false)
        
        let addPersonScreenNavigationController = UINavigationController(rootViewController: addPersonScreen)
        
        // Cancel
        addPersonScreen.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissViewController))
        
        // Next (add photo)
        addPersonScreen.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", primaryAction: UIAction() { [weak self] _ in
            guard let name = self?.addPersonScreen.getTextFieldText() else { return }
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let alertController = UIAlertController(title: "Oops", message: "Please enter a name before proceeding.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
                addPersonScreenNavigationController.present(alertController, animated: true)
                
                return
            }
            
            self?.person = Person(name: name, image: nil)
            
            let addPhotoScreen =
                AppleEsqueViewController(title: "Add a Photo for\n\"\(name)\"",
                                         titleToContentGap: (self?.getScreenDimensions().height)! / 60, contentGap: 25,
                                         addSecondaryButton: true)
            
            // Continue to add photo
            addPhotoScreen.setPrimaryButtonAction(UIAction() { [weak self] _ in
                self?.personIndex = 1
                self?.showImagePicker(fromViewController: addPhotoScreen)
            })
            // Skip
            addPhotoScreen.setSecondaryButtonAction(UIAction() { [weak self] _ in
                guard let person = self?.person else { return }
                self?.people.insert(person, at: 1)
                self?.save()
                self?.showAddPersonSuccessScreen(name: name) // Skip adding photo
            })
            guard let height = self?.getScreenDimensions().height else { return }
            addPhotoScreen.addMainIcon(UIImage(systemName: "person.crop.artframe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))!, withCustomTopPadding: height/50)
            addPhotoScreen.addDescription("This helps you recognize the person in case you forget their name.")
            
            self?.addPersonScreen.navigationController?.pushViewController(addPhotoScreen, animated: true)
        })
        addPersonScreen.navigationItem.rightBarButtonItem?.style = .done
        
        // Customizations
        addPersonScreen.addMainIcon(UIImage(systemName: "person.crop.square.filled.and.at.rectangle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))!, withCustomTopPadding: getScreenDimensions().height/50)
        addPersonScreen.addDescription("This helps you identify the person in case you forget their face.")
        addPersonScreen.addTextField(placeholder: "e.g. \"Steve Jobs\"")
        addPersonScreen.setTextFieldAutocapitalizationType(.words)
        
        addPersonScreenNavigationController.modalPresentationStyle = .formSheet
        
        present(addPersonScreenNavigationController, animated: true)
    }

    func showAddPersonSuccessScreen(name: String = "_unknown") {
        let successScreen = AppleEsqueViewController(title: "Successfully added \n\"\(name)\"",
                                                       titleToContentGap: getScreenDimensions().height / 60, contentGap: 28,
                                                       primaryButtonTitle: "Done")
        successScreen.addMainIcon(UIImage(systemName: "checkmark.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))!, withCustomTopPadding: getScreenDimensions().height/50)
        successScreen.addDescription("You can change a person's name and photo by long-pressing on their profile.")
        
        successScreen.setPrimaryButtonAction(UIAction() { [weak self] _ in
            self?.addPersonScreen.dismiss(animated: true)
            self?.addPersonScreen = nil
            DispatchQueue.main.async { // Play add cell animation
                self?.collectionView.performBatchUpdates({
//                        self?.collectionView.reloadSections(IndexSet(integer: 0))
//                        self?.collectionView.reloadData()
                    self?.collectionView.insertItems(at: [IndexPath(item: 1, section: 0)])
                }, completion: { (finished) -> Void in

                })
            }
        })
        
        successScreen.isModalInPresentation = true // Prevent view dismissal by swipping down
        
        // Preventing back navigation
        successScreen.navigationItem.hidesBackButton = true
        addPersonScreen.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        addPersonScreen.navigationController?.pushViewController(successScreen, animated: true)
    }
    
    func showRenamePersonScreen(forPerson person: Person) {
        let renamePersonScreen =
        AppleEsqueViewController(title: "Enter a New Name for \"\(person.name)\"",
                                 titleToContentGap: getScreenDimensions().height / 33, contentGap: 28,
                                 addPrimaryButton: false)
        let renamePersonScreenNavigationController = UINavigationController(rootViewController: renamePersonScreen)
        
        renamePersonScreen.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissViewController))
        
        // Rename button
        renamePersonScreen.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Rename", primaryAction: UIAction() {
            [weak self, weak person, weak renamePersonScreen, weak renamePersonScreenNavigationController] _ in
            guard let name = renamePersonScreen?.getTextFieldText() else { return }
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let alertController = UIAlertController(title: "Oops", message: "Please enter a name before proceeding.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
                renamePersonScreenNavigationController?.present(alertController, animated: true)
                
                return
            }
            
            person?.name = name
            
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                self?.dismiss(animated: true)
            }
        })
        renamePersonScreen.navigationItem.rightBarButtonItem?.style = .done
        
        // Customizations
        renamePersonScreen.addMainIcon(UIImage(systemName: "square.and.pencil", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64))!)
        renamePersonScreen.addTextField(placeholder: "e.g. \"Steve Jobs\"")
        renamePersonScreen.setTextFieldAutocapitalizationType(.words)
        
        present(renamePersonScreenNavigationController, animated: true)
    }
    
    @objc func showUpcomingFeaturesScreen() {
        let upcomingFeaturesScreen =
        AppleEsqueViewController(title: "Upcoming Features", primaryButtonTitle: "Done", addSecondaryButton: true, secondaryButtonTitle: "Special Thanks", secondaryButtonAction: UIAction() { [weak self] _ in
            self?.dismiss(animated: true)
            self?.showSpecialThanksScreen()
        })
        
        upcomingFeaturesScreen.addMainIcon(UIImage(systemName: "star.leadinghalf.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 56))!)
        
//        upcomingFeaturesScreen.addInfoView(title: "Persistent Storage",
//                                           subtitle: "As you might have noticed, added people are not retained after the app restarts. This will be sorted out in the near future (hopefully).",
//                                           icon: UIImage(systemName: "externaldrive.badge.checkmark"))
        upcomingFeaturesScreen.addInfoView(title: "Support for Dynamic Type",
                                           subtitle: "Texts and other components will adjust their size according to the Text Size settings. You can set your device's text size in Settings > Display & Brightness > Text Size.",
                                           icon: UIImage(systemName: "textformat.size"))
        
        upcomingFeaturesScreen.setSecondaryButtonImage(UIImage(systemName: "sparkles"), placement: .leading)
        
        present(upcomingFeaturesScreen, animated: true)
    }
    
    @objc func showSpecialThanksScreen() {
        guard let url = URL(string: "https://unsplash.com/s/photos/portrait") else { return }
        
        let specialThanksScreen = AppleEsqueViewController(title: "Special Thanks", primaryButtonTitle: "Done", addSecondaryButton: true)
        
        specialThanksScreen.addMainIcon(UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 56))!)
        
        specialThanksScreen.addInfoView(title: "Project Idea",
                                 subtitle: "This app was created originally as part of the 100 Days of Swift course created by @TwoStraws. A few \"extensions\" (like these cool info screens) were also added as an effort to further practice and explore how to make a user-friendly, Apple-esque iOS app.",
                                 icon: UIImage(systemName: "lightbulb.circle"));
        specialThanksScreen.addInfoView(title: "Placeholder Photos",
                                 subtitle: "Photos of placeholder users provided by Joseph Gonzalez, Albert Dera, Štefan Štefančík, Jurica Koletić, Robert Godwin, Mateus Campos Felipe, and Ali Morshedlou (in order of appearance) on Unsplash.",
                                 icon: UIImage(systemName: "person.crop.rectangle.stack"));
        
        specialThanksScreen.setSecondaryButtonTitle("Visit \"\(url.host()!)\"")
        specialThanksScreen.setSecondaryButtonImage(UIImage(systemName: "arrow.up.forward.app"))
        specialThanksScreen.setSecondaryButtonAction(UIAction() { _ in
            let alertController = UIAlertController(title: nil, message: "Visit \"\(url.host()!)\"?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            })
            
            specialThanksScreen.present(alertController, animated: true)
        })
        
        present(specialThanksScreen, animated: true)
    }
    
    // MARK: - Utilities functions -
    
    func save() {
        let defaults = UserDefaults.standard
        
        // Codable Person code (using JSONEncoder)
        let encoder = JSONEncoder()
        if let peopleData = try? encoder.encode(people) {
            defaults.set(peopleData, forKey: "people")
        }
        
        // NSCoding Person code (using NSKeyedArchiver)
//        if let peopleData = try? NSKeyedArchiver.archivedData(withRootObject: people, requiringSecureCoding: false) {
//            defaults.set(peopleData, forKey: "people")
//        }
        
        else {
            print("Unable to save people data.")
        }
    }
    
    // Thanks to @TwoStraws
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getScreenDimensions() -> CGSize {
        var width = UIScreen.main.bounds.width,
            height = UIScreen.main.bounds.height
        
        if width > height {
            width = height
            height = UIScreen.main.bounds.width
        }
        
        return CGSize(width: width, height: height)
    }
    
    func calculateCellDimensions() -> CGSize {
        let screenWidth = getScreenDimensions().width
        var cellsOnVerticalScreen = 2 // iPhones, iPod
        
        if screenWidth > 900 { // iPad Pro 12.9"
            cellsOnVerticalScreen = 6
        }
        else if screenWidth > 700 { // iPad, iPad mini, iPad Air, iPad Pro 11"
            cellsOnVerticalScreen = 4
        }
        
        let cellWidth = screenWidth / CGFloat(cellsOnVerticalScreen) - 8 * 2,
            cellHeight = cellWidth + 40
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func performActionAfterConfirmation(title: String? = nil, message: String, actionTitle: String, cancelTitle: String = "Cancel", handler: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        present(alertController, animated: true)
    }
    
    @objc func dismissViewController() {
        self.dismiss(animated: true)
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        let point = gesture.location(in: self.collectionView)

        if let indexPath = self.collectionView.indexPathForItem(at: point) {
            if gesture.state == .began {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred() // Haptic feedback
                
                if indexPath.item != 0 { // Not add button (no long press option?)
                    showOptionsForCellAt(indexPath)
                }
            }
        } else {
            print("Unable to find index path")
        }
    }
    
    // MARK: Authentication (project 28 challenge)
    
    func lock() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "lock")
            self.removePeople()
            self.lockedMessage.isHidden = false
        }
        isLocked = true
    }
    
    func unlock() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "lock.open")
            self.loadPeople()
            self.lockedMessage.isHidden = true
        }
        isLocked = false
    }
    
    @objc func toggleLock() {
        if !isLocked { // Content is unlocked.
            // Lock content now.
            lock()
            return
        }
        
        // Content is locked -> authenticate to unlock.
        // Authentication.
        let context = LAContext()
        var errorObject: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &errorObject) {
            // Touch ID/Face ID is available and enrolled.
            let reason = "Authentication is required to unlock and view content." // Touch ID usage description (Face ID's is in Info.plist).
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                if success {
                    // Authenticated.
                    self?.unlock()
                } else {
                    // Error occured.
                }
            }
        } else {
            // Touch ID/Face ID is unavailable or unenrolled -> use password.
            if let storedPassword = KeychainWrapper.standard.string(forKey: "password") {
                // Password already set up -> prompt to input password -> unlock.
                let passwordPrompt = UIAlertController(title: "View Content", message: "Enter the password you set.", preferredStyle: .alert)
                passwordPrompt.addTextField()
                passwordPrompt.textFields?[0].placeholder = "Password"
                passwordPrompt.textFields?[0].isSecureTextEntry = true
                
                passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                passwordPrompt.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    guard let enteredPassword = passwordPrompt.textFields?[0].text else { return }
                    
                    if enteredPassword.isEmpty {
                        self?.tryAgain(reason: "Password is Empty")
                        return
                    }
                    
                    if enteredPassword != storedPassword {
                        self?.tryAgain(reason: "Incorrect Password")
                    } else {
                        self?.unlock()
                    }
                })
                present(passwordPrompt, animated: true)
            }
            
            // Password not set up -> prompt to set up password -> unlock.
            let passwordSetupAlert = UIAlertController(title: "Biometrics Authentication Unavailable", message: "Would you like to set up and use a password instead?", preferredStyle: .alert)
            passwordSetupAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            passwordSetupAlert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
                // Set up password.
                let passwordInput = UIAlertController(title: "Create a Password", message: "Enter a secure password.", preferredStyle: .alert)
                passwordInput.addTextField()
                passwordInput.textFields?[0].placeholder = "Password"
                passwordInput.textFields?[0].isSecureTextEntry = true
                
                passwordInput.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                passwordInput.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                    guard let enteredPassword = passwordInput.textFields?[0].text else { return }
                    
                    if enteredPassword.isEmpty {
                        self?.tryAgain(reason: "Password is Empty")
                        return
                    }
                    
                    // Confirm password.
                    let passwordConfirmationInput = UIAlertController(title: "Confirm Password", message: "Enter the password again to confirm.\nNote that you might not be able to unlock the content if you forget this password.", preferredStyle: .alert)
                    passwordConfirmationInput.addTextField()
                    passwordConfirmationInput.textFields?[0].placeholder = "Password"
                    passwordConfirmationInput.textFields?[0].isSecureTextEntry = true
                    
                    passwordConfirmationInput.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    passwordConfirmationInput.addAction(UIAlertAction(title: "Set Password", style: .destructive) { _ in
                        guard let confirmedPassword = passwordConfirmationInput.textFields?[0].text else { return }
                        
                        if enteredPassword == confirmedPassword {
                            // Store password in keychain.
                            KeychainWrapper.standard.set(confirmedPassword, forKey: "password")
                            self?.unlock()
                        } else {
                            self?.tryAgain(reason: "Passwords Don't Match")
                        }
                    })
                    self?.present(passwordConfirmationInput, animated: true)
                })
                self?.present(passwordInput, animated: true)
            })
            present(passwordSetupAlert, animated: true)
        }
    }
    
    func tryAgain(reason: String?) {
        let alert = UIAlertController(title: reason, message: "Try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func loadPeople() {
        let defaults = UserDefaults.standard
        if let savedPeople = defaults.object(forKey: "people") as? Data { // Saved data exists
            // Codable Person (using JSONDecoder)
            let jsonDecoder = JSONDecoder()
            do {
                people = try jsonDecoder.decode([Person].self, from: savedPeople) // Attempting to create array of Person object from saved json data, then asign that array to people[]
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } catch {
                print("Unable to load people.")
                addPlaceholderCells()
            }
            
            // NSCoding Person (using NSKeyedUnarachiver)
//            if let decodedPeople = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedPeople) as? [Person] {
//                people = decodedPeople
//            } else {
//                print("Unable to load people.")
//                addPlaceholderCells()
//            }
        } else { // First launch; create placeholders
            addPlaceholderCells()
        }
    }
    
    func removePeople() {
        save()
        people = []
        collectionView.reloadData()
    }
    
}

