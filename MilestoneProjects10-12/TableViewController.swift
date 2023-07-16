//
//  TableViewController.swift
//  MilestoneProjects10-12
//
//  Created by Антон Кашников on 15.07.2023.
//

import UIKit
import PhotosUI

final class TableViewController: UITableViewController {
    private var photos = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My photos"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPhoto))
        
        if let savedPeople = UserDefaults.standard.object(forKey: "photos") as? Data {
            do {
                photos = try JSONDecoder().decode([Photo].self, from: savedPeople)
            } catch {
                print("Failes to load people.")
            }
        }
    }
    
    @objc private func addNewPhoto() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Take a photo", style: .default) { [weak self] _ in
            self?.makeImagePickerController(with: .camera)
        })
        alertController.addAction(UIAlertAction(title: "Photo library", style: .default) { [weak self] _ in
            if #available(iOS 14.0, *) {
                self?.makePickerViewController()
            } else {
                self?.makeImagePickerController(with: .photoLibrary)
            }
        })
        present(alertController, animated: true)
    }
    
    private func makeImagePickerController(with sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            return
        }
        
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @available(iOS 14.0, *)
    private func makePickerViewController() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    private func croppedImage(_ image: UIImage) -> UIImage {
        let sideLength = min(image.size.width, image.size.height)
        
        let sourceSize = image.size
        let xOffset = (sourceSize.width - sideLength) / 2
        let yOffset = (sourceSize.height - sideLength) / 2
        
        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength).integral
        
        let sourceCGImage = image.cgImage
        guard let croppedCGImage = sourceCGImage?.cropping(to: cropRect) else {
            return UIImage()
        }
        return UIImage(cgImage: croppedCGImage)
    }
    
    private func saveImage(_ image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath: URL
        
        if #available(iOS 16.0, *) {
            imagePath = getDocumentsDirectory().appending(path: imageName)
        } else {
            imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        }
        
        if let jpegData = image.jpegData(compressionQuality: 1) {
            try? jpegData.write(to: imagePath)
        }
        
        photos.append(Photo(imageName: imageName))
        saveData()
        tableView.reloadData()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveData() {
        if let savedData = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(savedData, forKey: "photos")
        } else {
            print("Failed to save people.")
        }
    }
}

// MARK: - UITableViewDataSource
extension TableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell", for: indexPath) as? PhotoTableViewCell else {
            fatalError("Unable to dequeue PersonCell.")
        }

        let photo = photos[indexPath.row]
        let imagePath: URL
        
        if #available(iOS 16.0, *) {
            imagePath = getDocumentsDirectory().appending(path: photo.imageName)
            cell.photoImageView.image = UIImage(contentsOfFile: imagePath.path())
        } else {
            imagePath = getDocumentsDirectory().appendingPathComponent(photo.imageName)
            cell.photoImageView.image = UIImage(contentsOfFile: imagePath.path)
        }

        cell.titleLabel.text = photo.title
        cell.descriptionLabel.text = photo.description

        cell.photoImageView.layer.borderWidth = 2
        cell.photoImageView.layer.cornerRadius = 3

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Add title and description", style: .default) { [weak self] _ in
            let textAlertController = UIAlertController(title: "Text title for the photo", message: nil, preferredStyle: .alert)
            textAlertController.addTextField()
            textAlertController.addTextField()
            textAlertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak textAlertController] _ in
                guard let self, let title = textAlertController?.textFields?[0].text, let description = textAlertController?.textFields?[1].text else {
                    return
                }
                
                self.photos[indexPath.row].title = title
                self.photos[indexPath.row].description = description
                self.saveData()
                self.tableView.reloadData()
            })
            self?.present(textAlertController, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Delete photo", style: .default) { [weak self] _ in
            self?.photos.remove(at: indexPath.row)
            self?.saveData()
            self?.tableView.reloadData()
        })
        alertController.addAction(UIAlertAction(title: "Show photo", style: .default) { [weak self] _ in
            guard let detailViewController = self?.storyboard?.instantiateViewController(identifier: "DetailViewController") as? DetailViewController, let photoImageName = self?.photos[indexPath.row].imageName else {
                return
            }
            
            if #available(iOS 16.0, *) {
                guard let imagePath = self?.getDocumentsDirectory().appending(path: photoImageName) else {
                    return
                }
                detailViewController.imagePath = imagePath.path()
            } else {
                guard let imagePath = self?.getDocumentsDirectory().appendingPathComponent(photoImageName) else {
                    return
                }
                detailViewController.imagePath = imagePath.path
            }
            
            self?.navigationController?.pushViewController(detailViewController, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension TableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        saveImage(image)
        dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14.0, *)
extension TableViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            return
        }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                DispatchQueue.main.async {
                    if let image = object as? UIImage, let croppedImage = self?.croppedImage(image) {
                        self?.saveImage(croppedImage)
                    } else if error != nil {
                        self?.saveImage(UIImage(systemName: "exclamationmark.circle") ?? UIImage())
                    }
                }
            }
        }
    }
}
