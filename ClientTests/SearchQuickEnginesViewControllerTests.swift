// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SnapshotTesting

import XCTest

@testable import Client

class SearchQuickEnginesViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        isRecording = false //snapshotRecordMode
        
//        let testEngine = OpenSearchEngine(engineID: "ATester", shortName: "ATester", image: UIImage(), searchTemplate: "http://firefox.com/find?q={searchTerm}", suggestTemplate: nil, isCustomEngine: true)
//        let engines = SearchEngines(files: profile.files)
//        try! engines.addSearchEngine(testEngine)
        
        
    }

    override func tearDown() {
        subject = nil
        
        super.tearDown()
    }

    func testDefaultQuickSearchEngines() {
        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(subject)
    }
    
    func testCustomQuickSearchEngines() throws {

        let testEngine = OpenSearchEngine(
            engineID: "ATester",
            shortName: "ATester",
            image: UIImage(),
            searchTemplate: "http://firefox.com/find?q={searchTerm}",
            suggestTemplate: nil,
            isCustomEngine: true)

        try! profile.searchEngines.addSearchEngine(testEngine)

        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(subject)
    }

    private var subject: SearchQuickEnginesViewController!
    private var profile = MockProfile()
}
