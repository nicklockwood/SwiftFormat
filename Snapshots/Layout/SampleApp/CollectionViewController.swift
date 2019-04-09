//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import UIKit

private let images = [
    UIImage(named: "Boxes"),
    UIImage(named: "Pages"),
    UIImage(named: "Text"),
    UIImage(named: "Table"),
    UIImage(named: "Collection"),
    UIImage(named: "Rocket"),
]

class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var collectionView: UICollectionView? {
        didSet {
            collectionView?.registerLayout(
                named: "CollectionCell.xml",
                forCellReuseIdentifier: "standaloneCell"
            )
        }
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return 500
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = (indexPath.row % 2 == 0) ? "templateCell" : "standaloneCell"
        let node = collectionView.dequeueReusableCellNode(withIdentifier: identifier, for: indexPath)
        let image = images[indexPath.row % images.count]!

        node.setState([
            "row": indexPath.row,
            "image": image,
            "whiteImage": image.withRenderingMode(.alwaysOriginal),
        ])

        return node.view as! UICollectionViewCell
    }
}
