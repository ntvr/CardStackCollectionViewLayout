//
//  ViewController.swift
//  CardCollectionViewLayout
//
//  Created by Michal Štembera on 08/04/2018.
//  Copyright © 2018 Michal Štembera. All rights reserved.
//
import UIKit

class ViewController: UIViewController {

    private let normalCellIdentifier = "cell.identifier.normal"
    private let supplementaryViewIdentifier = "supplementary.view"

    weak var collectionLayout: CardCollectionViewLayout!
    weak var collectionView: UICollectionView!

    override func loadView() {
        super.loadView()

        let collectionLayout = CardCollectionViewLayout()
        self.collectionLayout = collectionLayout

        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: collectionLayout)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: normalCellIdentifier)
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionElementKindCardInfo,
                                withReuseIdentifier: supplementaryViewIdentifier)
        view.addSubview(collectionView)
        self.collectionView = collectionView

        setupLayout()
        setupAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
    }
}

extension ViewController {
    func setupLayout() {
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func setupAppearance() {
        view.backgroundColor = .white

        collectionView.backgroundColor = .white
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: normalCellIdentifier, for: indexPath)
        cell.backgroundColor = indexPath.row % 2 == 0 ? .red : .green
        cell.layer.cornerRadius = 10
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindCardInfo,
                                                                   withReuseIdentifier: supplementaryViewIdentifier,
                                                                   for: indexPath)
        view.backgroundColor = .blue
        return view
    }
}
