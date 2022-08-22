//
//  Constants.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/20/22.
//

import Foundation
import Collections

let HEADING_TAGS: OrderedSet<String> = [
    "\\h1",
    "\\h2",
    "\\h3",
    "\\h4",
    "\\h5",
    "\\h6",
]

/// Overrides HTML tags if present.
let AML_TAGS: OrderedSet<String> = [
    "\\",
    "\\note",
    "\\grid",
    "\\math",
]

let ALLOWED_HTML_TAGS: OrderedSet<String> = [
    "\\h1",
    "\\h2",
    "\\h3",
    "\\h4",
    "\\h5",
    "\\h6",
    "\\blockquote",
    "\\dd",
    "\\dl",
    "\\dt",
    "\\figcaption",
    "\\figure",
    "\\hr",
    "\\li",
    "\\ol",
    "\\p",
    "\\pre",
    "\\ul",
    "\\a",
    "\\b",
    "\\br",
    "\\cite",
    "\\code",
    "\\em",
    "\\i",
    "\\mark",
    "\\q",
    "\\s",
    "\\small",
    "\\strong",
    "\\sub",
    "\\sup",
    "\\time",
    "\\u",
    "\\img",
    "\\table",
    "\\tbody",
    "\\td",
    "\\tfoot",
    "\\th",
    "\\tr",
]

let INLINE_HTML_TAGS: OrderedSet<String> = [
    "\\a",
    "\\b",
    "\\br",
    "\\code",
    "\\em",
    "\\i",
    "\\mark",
    "\\q",
    "\\s",
    "\\small",
    "\\strong",
    "\\sub",
    "\\sup",
    "\\u",
]

protocol GetKey {
    associatedtype Key
    associatedtype Value: Identifiable where Value.ID == Key
}

final class LookupTable<T: GetKey> {
    private var setData: OrderedDictionary<T.Key, [T.Value]> = [:]
    func insert(_ value: T.Value) {
        let key = value.id
        setData.updateValue(
            forKey: key,
            default: [value],
            with: {xs in
                xs.append(value)
            }
        )
    }
    func lookup<U>(key: T.Key, target: (T.Value) -> U?) -> U? {
        if let vs = setData[key] {
            for v in vs {
                if let u = target(v) {
                    return u
                }
            }
        }
        return nil
    }
}

