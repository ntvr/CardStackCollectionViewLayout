//  CardCollectionViewController.swift
//  CryptoApp
//
//  Created by Michal Štembera on 16/03/2018.
//  Copyright © 2018 NETVOR s.r.o. All rights reserved.
//

import Foundation
import UIKit

let UICollectionElementKindCardInfo = "UICollectionElementKindCardInfo"



class CardCollectionViewLayout: UICollectionViewLayout {
    private let itemsLayout: LayoutProtocol =
        PerspectiveLayout(viewType: .cell,
                          verticalLayout: ScaledVerticalLayout(),
                          horizontalLayout: PerspectiveHorizontalLayout())


    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }
        let itemsCount = collectionView.numberOfItems(inSection: 0)
        guard itemsCount > 0 else {
            return .zero
        }

        let lastIndexPath = IndexPath(item: itemsCount - 1, section: 0)
        let maxY = itemsLayout.layoutAttributes(at: lastIndexPath, for: collectionView).frame.maxY

        return CGSize(width: collectionView.bounds.width
            - collectionView.contentInset.left
            - collectionView.contentInset.right,
                      height: maxY - collectionView.contentInset.top)
    }

    override func prepare() {
        super.prepare()
        if let collectionView = collectionView {
            itemsLayout.prepare(with: collectionView)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemsLayout.layoutAttributesForElements(in: rect)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return nil
        }

        return itemsLayout.layoutAttributes(at: indexPath, for: collectionView)
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath
        ) -> UICollectionViewLayoutAttributes? {
        return nil
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: - Gathering the layout

protocol LayoutProtocol {
    func prepare(with collectionView: UICollectionView)

    func layoutAttributes(at indexPath: IndexPath,
                          for collectionView: UICollectionView) -> UICollectionViewLayoutAttributes

    func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]
}

enum CardLayoutViewType {
    case cell
    case supplementary(kind: String)
    case decorataion(kind: String)
}

class PerspectiveLayout: LayoutProtocol {
    private var layoutAttributes: [UICollectionViewLayoutAttributes]

    private let viewType: CardLayoutViewType
    private let verticalLayout: ScaledVerticalLayout
    private let horizontalLayout: PerspectiveHorizontalLayout
    

    init(viewType: CardLayoutViewType,
         verticalLayout: ScaledVerticalLayout,
         horizontalLayout: PerspectiveHorizontalLayout) {
            layoutAttributes = []
            self.viewType = viewType
            self.verticalLayout = verticalLayout
            self.horizontalLayout = horizontalLayout
    }

    func prepare(with collectionView: UICollectionView) {
        verticalLayout.prepare(with: collectionView)
        horizontalLayout.prepare(with: collectionView)

        let count = collectionView.numberOfItems(inSection: 0)
        layoutAttributes = (0..<count)
            .map { index in
                let indexPath = IndexPath(item: index, section: 0)
                let (minY, height) = verticalLayout.verticalAttributes(at: indexPath,
                                                                            for: collectionView)
                let (minX, width) = horizontalLayout.horizontalAttributes(at: indexPath,
                                                                          at: minY,
                                                                          for: collectionView)
                var viewAtttributes: UICollectionViewLayoutAttributes!
                switch viewType {
                case .cell:
                    viewAtttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                case .supplementary(let kind):
                    viewAtttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: kind,
                                                                       with: indexPath)
                case .decorataion(let kind):
                    viewAtttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: kind,
                                                                       with: indexPath)
                }
                viewAtttributes.frame = CGRect(x: minX, y: minY, width: width, height: height)
                return viewAtttributes
        }
    }

    func layoutAttributes(at indexPath: IndexPath,
                          for collectionView: UICollectionView) -> UICollectionViewLayoutAttributes {
        return layoutAttributes[indexPath.row]
    }

    func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return layoutAttributes.filter { $0.frame.intersects(rect) }
    }
}

class ScaledVerticalLayout {
    let elementHeight: CGFloat
    /// Vertical spacing between elements
    let spacing: CGFloat

    /// Defines from where the scaling should start (relative to collectionView's height)
    let scalingEdge: CGFloat
    /// Defines the scaling factor for vertical position
    let scalingFactor: CGFloat

    /// Taken from insets of collectionView
    var contentInsetTop: CGFloat = 0

    init(elementHeight: CGFloat = 100,
         spacing: CGFloat = 10,
         scalingEdge: CGFloat = 0.3,
         scalingFactor: CGFloat = 0.05) {
            assert(elementHeight >= 0)
            assert(scalingFactor > 0)

            self.elementHeight = elementHeight
            self.spacing = spacing
            self.scalingEdge = scalingEdge
            self.scalingFactor = scalingFactor
    }

    func prepare(with collectionView: UICollectionView) {
        contentInsetTop = collectionView.contentInset.top
    }

    func verticalAttributes(at indexPath: IndexPath,
                            for collectionView: UICollectionView) -> (positionY: CGFloat, height: CGFloat){
        let itemIndex = CGFloat(indexPath.item)
        let minY = contentInsetTop + itemIndex * (spacing + elementHeight)

        let currentScalingEdge = collectionView.contentOffset.y + scalingEdge
        var scaledMinY = minY

        if minY < currentScalingEdge {
            scaledMinY = currentScalingEdge - (currentScalingEdge - minY) * scalingFactor
        }

        return (scaledMinY, elementHeight)
    }
}

class PerspectiveHorizontalLayout {
    enum Perspective {
        /// - both bounds have to be between 0 and 1
        /// - point.x has to be between 0 ans 1
        /// - point.y is absolute
        case relative(point: CGPoint, boundsX: ClosedRange<CGFloat>)
        case absolute(point: CGPoint, boundsX: ClosedRange<CGFloat>)
    }

    private var perspective: Perspective = .relative(point: .zero, boundsX: 0...1)
    private var leftTangens: CGFloat = 0
    private var rightTangens: CGFloat = 0

    var perspectivePoint: CGPoint = .zero
    /// Used do determine normal horizontal attributes of layouted views
    var boundsX: ClosedRange<CGFloat> = 0...0
    /// Taken from insets of collectionView
    var insetXBounds: ClosedRange<CGFloat> = 0...0
    // TODO: Might be relative as well
    var perspectiveEdge: CGFloat = 0

    init(perspective: Perspective = .relative(point: CGPoint(x: 0.5, y: -200), boundsX: 0...1)) {
        if case let .relative(_, bounds) = perspective {
            let allowedRange: ClosedRange<CGFloat> = 0...1
            assert(allowedRange.contains(bounds.lowerBound))
            assert(allowedRange.contains(bounds.upperBound))
        }
        self.perspective = perspective
    }

    func prepare(with collectionView: UICollectionView) {
        let left = collectionView.contentInset.left
        let right = collectionView.contentInset.right
        let availableSpace = collectionView.bounds.width - left - right

        insetXBounds = left...(left + availableSpace)

        switch perspective {
        case .relative(let point, let boundsX):
            self.perspectivePoint = CGPoint(x: left + availableSpace * point.x, y: point.y)
            self.boundsX = (left + boundsX.lowerBound * availableSpace)...(left + boundsX.upperBound * availableSpace)
        case .absolute(let point, let boundsX):
            self.perspectivePoint = point
            self.boundsX = max(left, boundsX.lowerBound)...min(left + availableSpace, boundsX.upperBound)
        }

        leftTangens = (perspectivePoint.x - boundsX.lowerBound) / (perspectiveEdge - perspectivePoint.y)
        rightTangens = (boundsX.upperBound - perspectivePoint.x) / (perspectiveEdge - perspectivePoint.y)
    }

    func horizontalAttributes(at indexPath: IndexPath,
                              at verticalPosition: CGFloat,
                              for collectionView: UICollectionView) -> (positionX: CGFloat, width: CGFloat) {
        let verticalOrdinate = verticalPosition - collectionView.contentOffset.y - perspectivePoint.y
        let leftWidth = leftTangens * verticalOrdinate
        let rightWidth = rightTangens * verticalOrdinate

        let minXposition = insetXBounds.clampValue(perspectivePoint.x - leftWidth)
        let maxXPosition = insetXBounds.clampValue(perspectivePoint.x + rightWidth)

        return (minXposition, maxXPosition - minXposition)
    }
}
