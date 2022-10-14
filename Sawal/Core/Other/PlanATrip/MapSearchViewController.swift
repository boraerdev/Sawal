//
//  MapSearchViewController.swift
//  TestableApp
//
//  Created by Bora Erdem on 9.10.2022.
//

import UIKit
import LBTATools
import MapKit
import RxSwift
import RxCocoa

//Cell
final class MapSearchCell: LBTAListCell<MKMapItem> {
    
    override var item: MKMapItem! {
        didSet {
            nameLbl.text = item.name
            adressLbl.text = item.address()
        }
    }
    
    let nameLbl = UILabel()
    
    let adressLbl = UILabel(text: "", font: .systemFont(ofSize: 13), textColor: .secondaryLabel, textAlignment: .left, numberOfLines: 2)
    
    override func setupViews() {
        super.setupViews()
        stack(nameLbl, adressLbl).withMargins(.allSides(20))
        addSeparatorView()
        backgroundColor = .systemBackground
    }
}

final class MapSearchViewController: LBTAListController<MapSearchCell, MKMapItem> {
    
    //MARF: Def
    var selectionHandler: ((MKMapItem)->())?
    var prepareCurrentLocationForSearch: (()->())?
    var navBarHeight: CGFloat = 45
    var searchText: BehaviorRelay<String> = .init(value: "")
    let disposeBag = DisposeBag()
    
    //MARK: UI
    private lazy var searchField = IndentedTextField(placeholder: "Search...", padding: 10, cornerRadius: 8, backgroundColor: .secondarySystemBackground)
    
    private lazy var currentLocationBtn = UIButton(title: " Current Location", titleColor: .systemBackground, font: .systemFont(ofSize: 17), backgroundColor: .main3, target: self, action: #selector(didTapCur))

    //MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        performLocalSearch()
        prepareNavBar()
        prepareMainView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }
}

extension MapSearchViewController {
    
    private func prepareMainView() {
        collectionView.verticalScrollIndicatorInsets = .init(top: navBarHeight, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = .systemBackground
        
        if (prepareCurrentLocationForSearch == nil) {
            searchField.becomeFirstResponder()
        }
        
        searchField.rx.text.orEmpty
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind(to: searchText)
            .disposed(by: disposeBag)
    }
    
    @objc func didTapCur() {
        prepareCurrentLocationForSearch?()
        navigationController?.popViewController(animated: true)
    }
    
    private func performLocalSearch() {
        let request = MKLocalSearch.Request()
        var search: MKLocalSearch!
        searchText.subscribe { result in
            request.naturalLanguageQuery = result.element
            search = MKLocalSearch(request: request)
            search.start { [weak self] resp, err in
                guard err == nil else {return}
                self?.items = resp?.mapItems ?? []
            }
        }.disposed(by: disposeBag)
    }
    
    private func prepareNavBar() {
        let navBar = UIView(backgroundColor: .systemBackground)
        view.addSubview(navBar)

        navBar.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: -navBarHeight, right: 0))
        
        let containver = UIView(backgroundColor: .clear)
        navBar.addSubview(containver)
        containver.fillSuperviewSafeAreaLayoutGuide()
        
        let backBtn = UIButton(image: .init(systemName: "chevron.backward")!, tintColor: .main3, target: self, action: #selector(didTapBack))
        setupCurLocBtn()
        containver.hstack(backBtn.withWidth(25),searchField,spacing: 10).withMargins(.init(top: 0, left: 20, bottom: 0, right: 20))
        
    }
    
    func setupCurLocBtn() {
        guard prepareCurrentLocationForSearch != nil else {return}
        currentLocationBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentLocationBtn)
        currentLocationBtn.setImage(.init(systemName: "circle.circle"), for: .normal)
        currentLocationBtn.imageView?.contentMode = .scaleAspectFit
        currentLocationBtn.contentEdgeInsets = .init(top: 10, left: 20, bottom: 10, right: 20)
        currentLocationBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15).isActive = true
        currentLocationBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        currentLocationBtn.layer.cornerRadius = 8
        currentLocationBtn.tintColor = .systemBackground
    }
    
    @objc func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
}


extension MapSearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: view.frame.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        .init(0)
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mapItem = self.items[indexPath.item]
        selectionHandler?(mapItem)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: navBarHeight, left: 0, bottom: 0, right: 0)
    }
}