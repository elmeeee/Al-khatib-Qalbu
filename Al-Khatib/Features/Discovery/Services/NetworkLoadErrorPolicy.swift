//
//  NetworkLoadErrorPolicy.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

enum NetworkLoadErrorPolicy {
    static func shouldSurface(_ error: Error) -> Bool {
        if error is CancellationError { return false }
        if Task.isCancelled { return false }
        if let urlError = error as? URLError, urlError.code == .cancelled { return false }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return false }
        return true
    }
}
