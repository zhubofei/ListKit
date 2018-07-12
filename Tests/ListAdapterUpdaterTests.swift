//
//  ListAdapterUpdaterTests.swift
//  ListKitTests
//
//  Created by Bofei Zhu on 7/10/18.
//  Copyright © 2018 Bofei Zhu. All rights reserved.
//

import XCTest
@testable import ListKit

class ListAdapterUpdaterTests: XCTestCase {
    
    var window: UIWindow!
    var collectionView: UICollectionView!
    var dataSource: ListTestUICollectionViewDataSource!
    var updater: ListAdapterUpdater!
    var updateClosure: ListObjectTransitionClosure!
    var collectionViewClosure: ListCollectionViewClosure!
    
    override func setUp() {
        super.setUp()
        
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: window.frame, collectionViewLayout: layout)
        
        window.addSubview(collectionView)
        
        dataSource = ListTestUICollectionViewDataSource(collectionView: collectionView)
        updater = ListAdapterUpdater()
        updateClosure = { [unowned self] (objects: [AnyListDiffable]) in
            self.dataSource.sections = objects.map { $0.base as! ListTestSectionObject }
        }
        collectionViewClosure = { [unowned self] in
            return self.collectionView
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        collectionView = nil
        dataSource = nil
        updater = nil
        updateClosure = nil
        collectionViewClosure = nil
    }
    
    func testWhenUpdatingWithNilThatUpdaterHasNoChanges() {
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: nil, toObjectsClosure: nil,
                                  animated: true, objectTransitionClosure: updateClosure,
                                  completion: nil)
        XCTAssertFalse(updater.hasChanges)
    }
    
    func testWhenUpdatingtoObjectsThatUpdaterHasChanges() {
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: nil, toObjectsClosure: { [0].typeErased() },
                                  animated: true, objectTransitionClosure: updateClosure,
                                  completion: nil)
        XCTAssertTrue(updater.hasChanges)
    }
    
    func testWhenUpdatingfromObjectsThatUpdaterHasChanges() {
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: [0].typeErased(), toObjectsClosure: nil,
                                  animated: true, objectTransitionClosure: updateClosure,
                                  completion: nil)
        XCTAssertTrue(updater.hasChanges)
    }
    
    func testWhenUpdatingtoObjectsWithfromObjectsThatUpdaterHasChanges() {
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: [0].typeErased(),
                                  toObjectsClosure: { [1].typeErased() },
                                  animated: true, objectTransitionClosure: updateClosure,
                                  completion: nil)
        XCTAssertTrue(updater.hasChanges)
    }
    
    func testWhenCleaningUpStateWithChangesThatUpdaterHasNoChanges() {
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: nil,
                                  toObjectsClosure: { [0].typeErased() },
                                  animated: true, objectTransitionClosure: updateClosure,
                                  completion: nil)
        XCTAssertTrue(updater.hasChanges)
        updater.cleanStateBeforeUpdates()
        XCTAssertFalse(updater.hasChanges)
    }
    
    func testWhenReloadingDataThatCollectionViewUpdates() {
        dataSource.sections = [ListTestSectionObject(objects: [])]
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        dataSource.sections = []
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 0)
    }
    
    func testWhenInsertingSectionThatCollectionViewUpdates() {
        let from = [ListTestSectionObject(objects: [])]
        let to = {
            [ListTestSectionObject(objects: []),
             ListTestSectionObject(objects: [])].typeErased()
        }
        dataSource.sections = from
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        
        let expectation = XCTestExpectation(description: "Insert Section")
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: from.typeErased(),
                                  toObjectsClosure: to,
                                  animated: true,
                                  objectTransitionClosure: updateClosure) { [unowned self] (finished) in
                                    XCTAssertEqual(self.collectionView.numberOfSections, 2)
                                    expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testWhenDeletingSectionThatCollectionViewUpdates() {
        let from = [ListTestSectionObject(objects: []),
                    ListTestSectionObject(objects: [])]
        let to = {
            [ListTestSectionObject(objects: [])].typeErased()
        }
        dataSource.sections = from
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 2)
        
        let expectation = XCTestExpectation(description: "Delete Section")
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: from.typeErased(),
                                  toObjectsClosure: to,
                                  animated: true,
                                  objectTransitionClosure: updateClosure) { [unowned self] (finished) in
                                    XCTAssertEqual(self.collectionView.numberOfSections, 1)
                                    expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testWhenInsertingSectionWithItemChangesThatCollectionViewUpdates() {
        let from = [ListTestSectionObject(objects: [0].typeErased())]
        let to = {
            [ListTestSectionObject(objects: [0, 1].typeErased()),
             ListTestSectionObject(objects: [0, 1].typeErased())].typeErased()
        }
        
        dataSource.sections = from
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 1)
        
        let expectation = XCTestExpectation(description: "Insert Section")
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: from.typeErased(),
                                  toObjectsClosure: to,
                                  animated: true,
                                  objectTransitionClosure: updateClosure) { [unowned self] (finished) in
                                    XCTAssertEqual(self.collectionView.numberOfSections, 2)
                                    XCTAssertEqual(self.collectionView.numberOfItems(inSection: 0), 2)
                                    XCTAssertEqual(self.collectionView.numberOfItems(inSection: 1), 2)
                                    expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testWhenInsertingSectionWithDeletedSectionThatCollectionViewUpdates() {
        let from = [ListTestSectionObject(objects: [0, 1, 2].typeErased()),
                    ListTestSectionObject(objects: [])]
        let to = {
            [ListTestSectionObject(objects: [1, 1].typeErased()),
             ListTestSectionObject(objects: [0].typeErased()),
             ListTestSectionObject(objects: [0, 2, 3].typeErased())].typeErased()
        }
        
        dataSource.sections = from
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 2)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 3)
        
        let expectation = XCTestExpectation(description: "Insert and Delete Section")
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: from.typeErased(),
                                  toObjectsClosure: to,
                                  animated: true,
                                  objectTransitionClosure: updateClosure) { [unowned self] (finished) in
                                    XCTAssertEqual(self.collectionView.numberOfSections, 3)
                                    XCTAssertEqual(self.collectionView.numberOfItems(inSection: 0), 2)
                                    XCTAssertEqual(self.collectionView.numberOfItems(inSection: 1), 1)
                                    XCTAssertEqual(self.collectionView.numberOfItems(inSection: 2), 3)
                                    expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testWhenReloadingSectionsThatCollectionViewUpdates() {
        dataSource.sections = [ListTestSectionObject(objects: [0, 1].typeErased()),
                               ListTestSectionObject(objects: [0, 1].typeErased())]
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        XCTAssertEqual(collectionView.numberOfSections, 2)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 1), 2)
        
        dataSource.sections = [ListTestSectionObject(objects: [0, 1, 2].typeErased()),
                               ListTestSectionObject(objects: [0, 1].typeErased())]
        updater.collectionView(collectionView, reloadSections: IndexSet(integer: 0))
        XCTAssertEqual(collectionView.numberOfSections, 2)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 3)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 1), 2)
    }
    
    func testWhenCollectionViewNeedsLayoutThatPerformBatchUpdateWorks() {
        let from = [ListTestSectionObject(objects: []),
                    ListTestSectionObject(objects: [])]
        let to = {
            [ListTestSectionObject(objects: [])].typeErased()
        }
        
        dataSource.sections = from
        updater.performReloadDataWith(collectionViewClosure: collectionViewClosure)
        
        // the collection view has been setup with 1 section and now needs layout
        // calling performBatchUpdates: on a collection view needing layout will force layout
        // we need to ensure that our data source is not changed until the update block is executed
        collectionView.setNeedsLayout()
        
        let expectation = XCTestExpectation(description: "Layout Section")
        updater.performUpdateWith(collectionViewClosure: collectionViewClosure,
                                  fromObjects: from.typeErased(),
                                  toObjectsClosure: to,
                                  animated: false,
                                  objectTransitionClosure: updateClosure) { [unowned self] (finished) in
                                    XCTAssertEqual(self.collectionView.numberOfSections, 1)
                                    expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    
}