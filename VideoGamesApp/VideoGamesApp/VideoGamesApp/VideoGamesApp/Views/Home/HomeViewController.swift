//
//  HomeViewController.swift
//  VideoGamesApp
//
//  Created by Metin Tarık Kiki on 13.07.2023.
//

import UIKit
import GridLayout
import RAWG_API
import ImageViewPager
import NSLayoutConstraintExtensionPackage
import LoadingView
import TextStepperView

//MARK: - Fileprivate values
fileprivate typealias const = ApplicationConstants

fileprivate extension UIEdgeInsets {
    static let imageViewPagerMargin = UIEdgeInsets(
        top: 10,
        left: 10,
        bottom: 10,
        right: 10
    )
    
    static let searchFieldMargin = UIEdgeInsets(10)
    static let searchBarMargin = UIEdgeInsets(10)
    static let searchImageViewMargin = UIEdgeInsets(
        top: 0, left: 0, bottom: 0, right: 10
    )
    
    static let stepperMargin = UIEdgeInsets(10)
    static let collectionViewMargin = UIEdgeInsets(
        top: 10, left: 0, bottom: 5, right: 0
    )
}

extension HomeViewController {
    fileprivate enum Constants {
        static let imageViewPagerHeaderHeight: CGFloat = 200
        static let collectionContentInset = UIEdgeInsets(
            top: 0, left: 10, bottom: 10, right: 10
        )
    }
}

//MARK: - HomeviewControllerProtocol
protocol HomeViewControllerProtocol {
    func setupColors()
    func setupMainGrid()
}

//MARK: - HomeViewController View Implementations
class HomeViewController: UIViewController {
    
    lazy var collectionView: UICollectionView = {
        let layout = CollectionViewTableLayout(
            cellHeight: GamesListCell.defaultHeight,
            sectionInset: .zero
        )
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        
        collectionView.backgroundColor = .clear
        
        collectionView.register(
            GamesListCell.self,
            forCellWithReuseIdentifier: GamesListCell.reuseIdentifier
        )
        
        collectionView.register(
            ImageViewPagerReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ImageViewPagerReusableView.reuseIdentifier
        )
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    lazy var searchField: UITextField = {
        let searchField = UITextField()
        searchField.backgroundColor = .clear
        searchField.font = .preferredFont(forTextStyle: .title2)
        searchField.textColor = .white
        
        searchField.attributedPlaceholder = NSAttributedString(
            string: viewModel.viewControllerTitle,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.searchTintColor]
        )
        
        searchField.addTarget(
            self,
            action: #selector(searchDidChange(_:)),
            for: .editingChanged
        )
        
        searchField.delegate = self
        
        return searchField
    }()
    
    let searchImageView: UIImageView = {
        let searchImageView = UIImageView()
        searchImageView.image = UIImage(systemName: const.SystemImages.magnifyingGlass)
        searchImageView.contentMode = .scaleAspectFit
        searchImageView.tintColor = .searchTintColor
        return searchImageView
    }()
    
    lazy var searchBar: Grid = {
        let container = Grid.horizontal {
            searchField
                .Expanded(margin: .searchFieldMargin)
            searchImageView
                .Constant(value: 35,
                          margin: .searchImageViewMargin)
        }
        
        container.backgroundColor = .searchBackgroundColor
        
        return container
    }()
    
    lazy var textStepperView: TextStepperView = {
        let textStepperView = TextStepperView(
            startUpValue: viewModel.minimumPageNumber,
            stepperText: "Page:"
        )
        
        textStepperView.setDecreaseImage(UIImage(systemName: ApplicationConstants.SystemImages.chevronLeftCircle))
        textStepperView.setIncreaseImage(UIImage(systemName: ApplicationConstants.SystemImages.chevronRightCircle))
        
        textStepperView.stepperTextLabel.textColor = .white
        textStepperView.decreaseImageView.tintColor = .white
        textStepperView.increaseImageView.tintColor = .white
        
        textStepperView.minimumValue = viewModel.minimumPageNumber
        
        textStepperView.delegate = self
        
        return textStepperView
    }()
    
    let spacerView: UIView = {
        let spacerView = UIView()
        spacerView.backgroundColor = .darkGray
        return spacerView
    }()
    
    lazy var mainGrid = Grid.vertical {
        searchBar
            .Constant(value: 50)
        textStepperView
            .Constant(value: 50, margin: .stepperMargin)
        spacerView
            .Constant(value: 2)
        collectionView
            .Expanded(margin: .collectionViewMargin)
    }
    
    var viewModel: HomeViewModelProtocol! {
        didSet {
            title = viewModel.viewControllerTitle
            viewModel.delegate = self
        }
    }
    
    //MARK: - Overridden methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupColors()
        setupMainGrid()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LoadingView.shared.startLoading(on: collectionView)
        viewModel.performDefaultQuery(
            nil,
            pageNumber: viewModel.minimumPageNumber
        )
    }
    
    @objc private func searchDidChange(_ textField: UITextField) {
        //TODO: add logic for 3 letter search
        viewModel.queryForGamesList(
            textField.text,
            orderBy: nil,
            pageNumber: textStepperView.currentValue
        )
        LoadingView.shared.startLoading(on: collectionView)
    }
    
    @objc private func onViewTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

//MARK: - ImageViewPagerDelegate
extension HomeViewController: ImageViewPagerDelegate {
    func onImageTap(imageViewPager: ImageViewPager, at index: Int) {
        print(index)
    }
}

//MARK: - HomeViewControllerProtocol Implementation
extension HomeViewController: HomeViewControllerProtocol {
    
    func setupColors() {
        view.backgroundColor = .appTabBarColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.barTitleColor]
    }
    
    func setupMainGrid() {
        view.addSubview(mainGrid)
        mainGrid.backgroundColor = .appBackgroundColor
        mainGrid.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.expand(mainGrid, to: view.safeAreaLayoutGuide)
    }
}

//MARK: - UICollectionViewDataSource and Delegate implementations
extension HomeViewController: UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return viewModel.dataCount
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GamesListCell.reuseIdentifier,
            for: indexPath
        ) as? GamesListCell
        else { fatalError("Failed to cast GamesListCell") }
        
        cell.viewModel = GamesListCellViewModel(
            dataModel: viewModel.getGameForCell(at: indexPath.row)
        )
        
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let suppView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ImageViewPagerReusableView.reuseIdentifier,
            for: indexPath
        ) as? ImageViewPagerReusableView
        else {
            fatalError("Failed to cast ImageViewPagerReusableView in HomeViewController")
        }
        
        var imageURLStrings = [String?]()
        var titles = [String?]()
        
        let dataCount = viewModel.imageViewPagerCount
        
        for i in 0 ..< dataCount {
            let gameData = viewModel.getGameForHeader(at: i)
            imageURLStrings.append(gameData?.backgroundImageURLString)
            titles.append(gameData?.name)
        }
        
        suppView.viewModel = ImageViewPagerReusableViewModel(
            imageURLStrings: imageURLStrings,
            titles: titles
        )
        
        suppView.contentInset = Constants.collectionContentInset
        suppView.imageViewPager.delegate = self
        
        return suppView
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        
        let width: CGFloat = collectionView.bounds.size.width
        - Constants.collectionContentInset.left
        - Constants.collectionContentInset.right
        
        return viewModel.isImageViewPagerVisible
        ? .init(width: width, height: Constants.imageViewPagerHeaderHeight)
        : .zero
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        //TODO: navigate to detail
    }
}

//MARK: - ViewModel delegate implementations
extension HomeViewController: HomeViewModelDelegate {
    
    func onSearchResult() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            LoadingView.shared.hideLoading()
            collectionView.reloadData()
        }
    }
}

extension HomeViewController: TextStepperViewDelegate {
    func onCurrentValueChange(
        _ textStepperView: TextStepperView,
        oldValue: Int,
        newValue: Int
    ) {
        if oldValue != newValue {
            LoadingView.shared.startLoading(on: collectionView)
            viewModel.queryForGamesList(
                searchField.text,
                orderBy: nil,
                pageNumber: newValue
            )
        }
    }
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
