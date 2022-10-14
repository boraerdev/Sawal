//
//  PlanATripViewController.swift
//  TestableApp
//
//  Created by Bora Erdem on 8.10.2022.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa
import CoreLocation
import LBTATools
import AVFAudio

protocol PlanATripViewControllerInterFace: AnyObject {
}

//MARK: Def, UI
final class PlanATripViewController: UIViewController, PlanATripViewControllerInterFace {
    
    //MARK: Def
    var curRiskView: UIViewController?
    var isNowPlaying = false
    let disposeBag = DisposeBag()
    var tripAnnotations = [MKAnnotation]()
    let startAno: MKAnnotation? = nil
    let finishAno: MKAnnotation? = nil
    var mapView = MKMapView()
    let manager = CLLocationManager()
    static let viewModel = PlanATripViewModel()
    var startItem: MKMapItem? = nil
    var finishItem: MKMapItem? = nil

    //MARK: UI
    let directionsView = UIView(backgroundColor: .white.withAlphaComponent(0.3))
        
    private lazy var fieldsBG = UIView(backgroundColor: .main3)
    
    private lazy var startField = IndentedTextField(placeholder: "Start", padding: 10, cornerRadius: 8, backgroundColor: .white.withAlphaComponent(0.3))
    
    private lazy var finishField = IndentedTextField(placeholder: "Finish", padding: 10, cornerRadius: 8, backgroundColor: .white.withAlphaComponent(0.3))
    
    private lazy var startIcon = UIImageView(image: .init(systemName: "circle.circle"))
    
    private lazy var exitBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(.init(systemName: "xmark"), for: .normal)
        btn.tintColor = .main3
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(didTapExit), for: .touchUpInside)
        return btn
    }()
    
    let header = UIView(backgroundColor: .systemBackground)
    
    private lazy var startBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(" Go", for: .normal)
        btn.setTitleColor(.main3, for: .normal)
        btn.setImage(.init(systemName: "arrowtriangle.right"), for: .normal)
        btn.tintColor = .main3
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
        return btn
    }()
    
    private lazy var finishIcon = UIImageView(image: .init(systemName: "pin"))
    
}

//MARK: Core
extension PlanATripViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMainView()
        prepareFields()
        addTargets()
    }
    
    override func viewDidLayoutSubviews() {
        view.stack(header, mapView,fieldsBG)
        header.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor,padding: .init(top: 0, left: 0, bottom: -55, right: 0))
        
        let container = UIView(backgroundColor: .clear)
        header.addSubview(container)
        container.fillSuperviewSafeAreaLayoutGuide(padding: .init(top: 0, left: 20, bottom: 10, right: 20))
        
        //Add RsikView
        //showRiskView()
        
        PlanATripViewController.viewModel.riskMode.subscribe { [weak self] result in
            if result.element == .inAreaCloser || result.element == .inAreaAway {
                self?.AddRiskView()
                self?.isNowPlaying = true
            } else {
                self?.RemoveRiskView()
                self?.isNowPlaying = false
            }
        }.disposed(by: disposeBag)
        
        container.hstack(exitBtn.withWidth(45),directionsView, spacing: 12)
        fieldsBG.withHeight(250)
        setupSomeUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        PlanATripViewController.viewModel.fetchSharedLocations()
        handleSharedAnnotations()
        navigationController?.navigationBar.isHidden = true
        PlanATripViewController.viewModel.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        mapView.removeAnnotations(mapView.annotations)
    }
}

//MARK: Funcs
extension PlanATripViewController {
    
    private func AddRiskView() {
        guard !isNowPlaying else {return}
        let vc = RiskView()
        navigationController?.pushViewController(vc, animated: true)
        curRiskView = vc
    }
    
    private func RemoveRiskView() {
        guard isNowPlaying else {return}
        curRiskView?.navigationController?.popViewController(animated: true)
    }

    private func prepareMainView() {
        manager.delegate = self
        manager.startUpdatingLocation()
        mapView.delegate = self
        mapView.showsUserLocation = true
        PlanATripViewController.viewModel.view = self
    }
    
    private func prepareFields() {
        
        lazy var containerView = UIView()
        fieldsBG.addSubview(containerView)
        containerView.fillSuperviewSafeAreaLayoutGuide(padding: .init(top: 30, left: 20, bottom: 30, right: 20))
        
        [startField, finishField].forEach { field in
            field.withHeight(45)
            field.textColor = .white
        }
                
        startField.attributedPlaceholder = .init(string: "Start", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.7)])
        
        finishField.attributedPlaceholder = .init(string: "Finish", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.7)])
        
        [startIcon, finishIcon].forEach { icon in
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .white
        }
        
        containerView.stack(
            containerView.hstack(
                startIcon.withWidth(25)
                ,startField,
                spacing: 12,
                alignment: .center),
            containerView.hstack(
                finishIcon.withWidth(25)
                ,finishField,
                spacing: 12,
                alignment: .center),
            startBtn,
            spacing: 10,
            distribution: .fillEqually
        )
    }
    
    private func addTargets() {
        startField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapChangeStart)))
        finishField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapChangeFinish)))
    }
    
    private func setupSomeUI() {
        exitBtn.layer.cornerRadius = 8
        header.applyGradient(colours: [.main3,.main3Light])
        fieldsBG.applyGradient(colours: [.main3, .main3Light])
        directionsView.layer.cornerRadius = 8
    }
    
    private func addAnnotation(title: String, item: MKMapItem) {
        let annotation = DirectionEndPoint(type: title)
        annotation.coordinate = item.placemark.coordinate
        annotation.title = title
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
        self.tripAnnotations.append(annotation)
    }
    
    private func updateStartFinishAnnotations() {
        
        if let _ = startItem {
            if let ano = mapView.annotations.first(where: {$0.title == "Start"}) {
                mapView.removeAnnotation(ano)
                tripAnnotations.removeAll(where: {$0.title == "Start" || $0.title == "Finish"})
            }
            addAnnotation(title: "Start", item: startItem!)
        }
        
        if let _ = finishItem {
            if let ano = mapView.annotations.first(where: {$0.title == "Finish"}) {
                mapView.removeAnnotation(ano)
                tripAnnotations.removeAll(where: {$0.title == "Start" || $0.title == "Finish"})
            }
            addAnnotation(title: "Finish", item: finishItem!)
        }
        
        requestForDirections()
        mapView.showAnnotations(tripAnnotations, animated: false)
    }
    
    private func requestForDirections() {
        PlanATripViewController.viewModel.requestForDirections { [weak self] route in
            DispatchQueue.main.async {
                self?.tripAnnotations.removeAll(keepingCapacity: false)
                self?.mapView.removeOverlays(self?.mapView.overlays ?? [])
                self?.mapView.addOverlay(route.polyline)
            }
        }
        self.mapView.showAnnotations(tripAnnotations , animated: true)

    }
    
    private func handleSharedAnnotations() {
        PlanATripViewController.viewModel.posts.subscribe { [weak self] posts in
            posts.element?.forEach({ post in
                let ano = RiskColoredAnnotations(post: post)
                ano.coordinate = .init(latitude: post.location.latitude, longitude: post.location.longitude)
                DispatchQueue.main.async {
                    self?.mapView.addAnnotation(ano)
                }
            })
        }.disposed(by: disposeBag)
        //mapKit.showAnnotations(mapKit.annotations, animated: false)
    }
    
}

//MARK: CLMANAGERDelegate
extension PlanATripViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loca = locations.first {
            let span: MKCoordinateSpan = .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let center: CLLocationCoordinate2D = .init(latitude: loca.coordinate.latitude, longitude: loca.coordinate.longitude)
            let region: MKCoordinateRegion = .init(center: center, span: span)
            self.mapView.setRegion(region, animated: false)
        }
        manager.stopUpdatingLocation()
    }
}

//MARK: MapView Delegate
extension PlanATripViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is DirectionEndPoint || annotation is RiskColoredAnnotations) {return nil}
        
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "id")
        
        if let customAnnotation = annotation as? DirectionEndPoint {
            if customAnnotation.type == "Start" {
                annotationView.image = .init(named: "StartPin")
            } else if customAnnotation.type == "Finish" {
                annotationView.image = .init(named: "FinishPin")
            }
        } else {
            annotationView.canShowCallout = true
            if let customPin = annotation as? RiskColoredAnnotations {
                if customPin.post.riskDegree == 0 {
                    annotationView.image = .init(named: "LowPin")
                }else if customPin.post.riskDegree == 1 {
                    annotationView.image = .init(named: "MedPin")
                }else if customPin.post.riskDegree == 2 {
                    annotationView.image = .init(named: "HighPin")
                }
            }
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        PlanATripViewController.viewModel.currentLocation.accept(userLocation.coordinate)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
           let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .systemRed
           polylineRenderer.lineWidth = 5
           return polylineRenderer
       }
}

//MARK: Objc
extension PlanATripViewController {
    
    @objc func didTapExit() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func didTapStart() {
        guard startField.text != "", finishField.text != "" else {return}
        PlanATripViewController.viewModel.filterAndDetect { list in
            PlanATripViewController.viewModel.detectRisk(postList: list)
        }
    }

    @objc private func didTapChangeStart() {
        let vc = MapSearchViewController()
        vc.prepareCurrentLocationForSearch = { [weak self] in
            self?.startField.text = "Current Location"
            PlanATripViewController.viewModel.startLocation.accept(PlanATripViewController.viewModel.currentLocation.value)
            let item: MKMapItem = .init(placemark: .init(coordinate: PlanATripViewController.viewModel.currentLocation.value!))
            self?.addAnnotation(title: "Start", item: item)
        }
        vc.selectionHandler = { [unowned self] item in
            self.startField.text = item.name
            self.navigationController?.popViewController(animated: true)
            PlanATripViewController.viewModel.startLocation.accept(item.placemark.coordinate)
            self.startItem = item
            updateStartFinishAnnotations()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapChangeFinish() {
        let vc = MapSearchViewController()
        vc.selectionHandler = { [unowned self] item in
            self.finishField.text = item.name
            self.navigationController?.popViewController(animated: true)
            PlanATripViewController.viewModel.finishLocation.accept(item.placemark.coordinate)
            self.finishItem = item
            updateStartFinishAnnotations()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

}