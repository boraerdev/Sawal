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

protocol HomeViewControllerInterface: AnyObject {
}

final class HomeViewController: UIViewController {
    
    //MARK: Def
    let viewModel = HomeControllerViewModel()
    
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
        btn.setTitle("Share Risk", for: .normal)
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
    
    private var btnHStack: UIStackView!
    
    private var btnVStack: UIStackView!
    
    
    //MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.titleView = welcomeStack
        prepareStack()
        performButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.addSubview(btnVStack)
        NSLayoutConstraint.activate([
            btnVStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            btnVStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            btnVStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            btnVStack.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        goMapBtn.applyGradient(colours: [.main1,.main1Light])
        addRiskBtn.applyGradient(colours: [.main2,.main2Light])
        planTrpBtn.applyGradient(colours: [.main3,.main3Light])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func prepareStack() {
        btnHStack = .init(arrangedSubviews: [goMapBtn, addRiskBtn])
        btnHStack.axis = .horizontal
        btnHStack.distribution = .fillEqually
        btnHStack.spacing = 10
        
        btnVStack = .init(arrangedSubviews: [btnHStack,planTrpBtn])
        btnVStack.translatesAutoresizingMaskIntoConstraints = false
        btnVStack.axis = .vertical
        btnVStack.distribution = .fillEqually
        btnVStack.spacing = 10
    }
    
    private func performButtons() {
        goMapBtn.rx.tap.subscribe(onNext: { [unowned self] in
            navigationController?.tabBarController?.selectedIndex = 1
        })
        
        addRiskBtn.rx.tap.subscribe(onNext: {[unowned self] in
            navigationController?.pushViewController(ShareViewController(), animated: true)
        })
    }
    
}


