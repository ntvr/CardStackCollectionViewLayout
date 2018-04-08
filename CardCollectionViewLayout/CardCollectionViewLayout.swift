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
    let cardHeight: CGFloat = 100
    let verticalSpacing: CGFloat = 10
    let horizontalSpacing: CGFloat = 10

    /// - Perspective point to which the cards will convergate to.
    /// - Should be out of the screen.
    var perspectivePoint: CGPoint = .zero
    /// Y coordinate from where the cards begin to convergate to persepctive point
    var perspectiveEdge: CGFloat = 0
    var availableCellXRange: ClosedRange<CGFloat> = 0...0
    var availableInfoXrange: ClosedRange<CGFloat> = 0...0

    private var leftTangens: CGFloat = 1
    private var rightTangens: CGFloat = 1

    private var itemsLayoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var supplementaryLayoutAttributes: [UICollectionViewLayoutAttributes] = []

    override var collectionViewContentSize: CGSize {
        guard let lastFrame = itemsLayoutAttributes.last?.frame else {
            return .zero
        }

        let leftInset = collectionView?.contentInset.left ?? 0
        return CGSize(width: lastFrame.maxX - leftInset,
                      height: lastFrame.maxY)
    }

    override func prepare() {
        super.prepare()
        if let collectionView = collectionView {
            // TODO: Remove perspective point update from here
            perspectivePoint = CGPoint(x: collectionView.bounds.width * (2 / 3), y: -200)
            perspectiveEdge = collectionView.bounds.height / 4
            collectionView.contentInset.top = perspectiveEdge
            // Available x space
            let lowerBound = collectionView.bounds.width / 3
            let upperBound = collectionView.bounds.width - collectionView.contentInset.right
            availableCellXRange = lowerBound...upperBound
            availableInfoXrange = collectionView.contentInset.left...(lowerBound - horizontalSpacing)
            // Calculations of angles
            leftTangens = (perspectivePoint.x - lowerBound) / (perspectiveEdge - perspectivePoint.y)
            rightTangens = (upperBound - perspectivePoint.x) / (perspectiveEdge - perspectivePoint.y)
        }

        itemsLayoutAttributes = generateItemsLayoutAttributes()
        supplementaryLayoutAttributes = generateSupplementaryLayoutAttributes(from: itemsLayoutAttributes)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemsLayoutAttributes.filter { $0.frame.intersects(rect) }
            + supplementaryLayoutAttributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemsLayoutAttributes[indexPath.row]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath
        ) -> UICollectionViewLayoutAttributes? {
        return supplementaryLayoutAttributes[indexPath.row]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: - Gathering the layout

extension CardCollectionViewLayout {
    func generateItemsLayoutAttributes() -> [UICollectionViewLayoutAttributes] {
        guard let collectionView = collectionView else {
            return []
        }
        let count = collectionView.numberOfItems(inSection: 0)
        let offset = collectionView.contentOffset.y
        let splitEdge = offset + perspectiveEdge

        let splitIndex = (0..<count)
            .filter { generateNormalMinY(at: $0) < splitEdge }
            .last ?? 0

        let aboveSplitRange = 0..<splitIndex
        let belowSplitRange = splitIndex..<count

        let aboveSplit: [UICollectionViewLayoutAttributes] = aboveSplitRange.map { index in
            return generateLayoutAttributes(at: index,
                                            for: offset,
                                            scaled: 0.05)
        }

        let belowSplit: [UICollectionViewLayoutAttributes] = belowSplitRange.map { index in
            return generateLayoutAttributes(at: index,
                                            for: offset,
                                            scaled: 1.0)
        }

        return aboveSplit + belowSplit
    }

    func generateSupplementaryLayoutAttributes(from itemAttributes: [UICollectionViewLayoutAttributes]
        ) -> [UICollectionViewLayoutAttributes] {
        let contentOffset = collectionView?.contentOffset.y ?? 0.0
        return itemAttributes.map { itemAttributes in
            let attributes = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind: UICollectionElementKindCardInfo,
                with: itemAttributes.indexPath)

            let width: CGFloat = availableInfoXrange.upperBound - availableInfoXrange.lowerBound
            let minX = itemAttributes.frame.minX - 10 - width
            let top = itemAttributes.frame.minY
            attributes.frame = CGRect(x: minX,
                                      y: top,
                                      width: width,
                                      height: itemAttributes.frame.height)

            attributes.alpha = (0...1).clampValue((top - contentOffset - perspectiveEdge / 2)
                / max(1, perspectiveEdge))
            return attributes
        }
    }

    func generateStackedMinY(at index: Int,
                             `for` splitEdge: CGFloat,
                             scaled scaleFactor: CGFloat) -> CGFloat {
        let splitEdge = splitEdge - cardHeight
        let minY = generateNormalMinY(at: index)
        return splitEdge - (splitEdge - minY) * scaleFactor
    }

    func generateNormalMinY(at index: Int) -> CGFloat {
        let floatIdx = CGFloat(index)
        return (floatIdx + 1.0) * verticalSpacing + floatIdx * cardHeight
    }

    func generateLayoutAttributes(at index: Int,
                                  `for` contentOffset: CGFloat,
                                  scaled scaleFactor: CGFloat = 1.0
        ) -> UICollectionViewLayoutAttributes {
        let indexPath = IndexPath(item: index, section: 0)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let top = generateStackedMinY(at: index,
                                      for: contentOffset + perspectiveEdge,
                                      scaled: scaleFactor)
        // Calculating width
        let verticalOrdinate = top - contentOffset - perspectivePoint.y
        let leftWidth = leftTangens * verticalOrdinate
        let rightWidth = rightTangens * verticalOrdinate
        let frameX = availableCellXRange.clampValue(perspectivePoint.x - leftWidth)
        // Alpha in dependency on stack position
        attributes.alpha = (0...1).clampValue((top - contentOffset) / max(1, perspectiveEdge / 3))
        // z index and frame
        attributes.zIndex = index
        attributes.frame = CGRect(x: frameX,
                                  y: top,
                                  width: availableCellXRange.lengthRange
                                    .clampValue(leftWidth + rightWidth),
                                  height: cardHeight)
        return attributes
    }
}
