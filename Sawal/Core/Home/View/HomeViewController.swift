//
//  HomeViewController.swift
//  TestableApp
//
//  Created by Bora Erdem on 26.09.2022.
//

import UIKit
import FirebaseAuth
import RxSwift
import RxCocoa
import LBTATools

protocol HomeViewControllerInterface: AnyObject {
}

//MARK: Def, UI
final class HomeViewController: UIViewController {
    
    //MARK: Def
    let viewModel = HomeControllerViewModel()
    let disposeBag = DisposeBag()
    let sideMenu = SideMenuViewController()
    let darkBgForSideMenu = UIView(backgroundColor: .black.withAlphaComponent(0.1))

    
    //MARK: UI
    private lazy var goMapBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .red
        btn.layer.cornerRadius = 8
        btn.setTitle("Go Map", for: .normal)
        let bgImg = UIImageView(image: .init(systemName: "map.fill")!)
        bgImg.frame = .init(x: -20, y: 20, width: 100, height: 100)
        bgImg.contentMode = .scaleAspectFit
        bgImg.tintColor = .secondarySystemBackground
        bgImg.alpha = 0.3
        btn.clipsToBounds = true
        btn.addSubview(bgImg)
        return btn
    }()
    
    private lazy var welcomeStack: UIStackView = {
        let welcomeText = UILabel()
        welcomeText.text = "Welcome Back,"
        welcomeText.font = .systemFont(ofSize: 13)
        let name = UILabel()
        name.text = AuthManager.shared.currentUser?.fullName
        name.font = .boldSystemFont(ofSize: 13)
        let stack = UIStackView(arrangedSubviews: [welcomeText,name])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 4
        return stack
    }()
    
    private lazy var addRiskBtn: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 8
        btn.setTitle("Share a Risk", for: .normal)
        btn.setTitleColor(.secondarySystemBackground, for: .selected)
        let bgImg = UIImageView(image: .init(systemName: "square.and.arrow.up.trianglebadge.exclamationmark")!)
        bgImg.frame = .init(x: -20, y: 20, width: 100, height: 100)
        bgImg.contentMode = .scaleAspectFit
        bgImg.tintColor = .secondarySystemBackground
        bgImg.alpha = 0.3
        btn.clipsToBounds = true
        btn.addSubview(bgImg)
        return btn
    }()
    
    private lazy var planTrpBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .red
        btn.setTitle("Plan a Trip", for: .normal)
        let bgImg = UIImageView(image: .init(systemName: "paperplane")!)
        bgImg.frame = .init(x: -20, y: 20, width: 100, height: 100)
        bgImg.contentMode = .scaleAspectFit
        bgImg.tintColor = .secondarySystemBackground
        bgImg.alpha = 0.3
        btn.clipsToBounds = true
        btn.addSubview(bgImg)
        btn.layer.cornerRadius = 8
        return btn
    }()
    
}

//MARK: Core
extension HomeViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMainView()
        prepareStack()
        performButtons()
    }
}

//MARK: Funcs
extension HomeViewController {
    
    private func prepareMainView() {
        view.backgroundColor = .systemBackground
        navigationItem.titleView = welcomeStack
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .init(systemName: "line.3.horizontal"), style: .done, target: self, action: #selector(didTapMenu))
    }
    
    private func prepareSideMenu() {
        addChild(sideMenu)
        sideMenu.didMove(toParent: self)
        darkBgForSideMenu.isUserInteractionEnabled = true
        view.addSubview(darkBgForSideMenu)
        darkBgForSideMenu.fillSuperview()
        view.addSubview(sideMenu.view)
        sideMenu.view.frame = .init(x: -(view.frame.width * 0.8), y: 0, width: view.frame.width * 0.8, height: view.frame.height)
        darkBgForSideMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeMenu)))
    }
    
    private func prepareStack() {
        let container = UIView()
        container.withHeight(250)
        view.stack(container, UIView()).withMargins(.init(top: 10, left: 20, bottom:0, right: 20))
        
        container.stack(
            container.hstack(goMapBtn, addRiskBtn, spacing: 10, distribution: .fillEqually),
            planTrpBtn,
            spacing: 10,
            distribution: .fillEqually
        )
        
        DispatchQueue.main.async {
            self.goMapBtn.applyGradient(colours: [.main1,.main1Light])
            self.addRiskBtn.applyGradient(colours: [.main2,.main2Light])
            self.planTrpBtn.applyGradient(colours: [.main3,.main3Light])
        }
        
    }
    
    private func performButtons() {
        goMapBtn.rx.tap.subscribe(onNext: { [unowned self] in
            navigationController?.pushViewController(MapViewController(), animated: true)
        })
        .disposed(by: disposeBag)
        
        addRiskBtn.rx.tap.subscribe(onNext: {[unowned self] in
            let simulator = true
            simulator ? navigationController?.pushViewController(ShareViewController(), animated: true) :                     navigationController?.pushViewController(CameraView(), animated: true)
        })
        .disposed(by: disposeBag)
        
        planTrpBtn.rx.tap.subscribe(onNext: { [unowned self] in
            navigationController?.pushViewController(PlanATripViewController(), animated: true)
        })
        .disposed(by: disposeBag)
    }

}

//MARK: Objc
extension HomeViewController {
    @objc func didTapMenu() {
        welcomeStack.isHidden = true
        prepareSideMenu()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else {return}
            self.sideMenu.view.frame = .init(x: 0, y: 0, width: self.view.frame.width * 0.8, height: self.view.frame.height)
        }
    }
    
    @objc func closeMenu() {
        UIView.animate(withDuration: 0.2) { [unowned self] in
            self.sideMenu.view.frame = .init(x: -(self.view.frame.width * 0.8), y: 0, width: self.view.frame.width * 0.8, height: self.view.frame.height)

        } completion: { isFinish in
            self.sideMenu.view.removeFromSuperview()
            self.darkBgForSideMenu.removeFromSuperview()
            self.welcomeStack.isHidden = false
        }
    }
}