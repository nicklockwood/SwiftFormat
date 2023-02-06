//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

typealias LayoutLoaderCallback = (LayoutNode?, LayoutError?) -> Void

func clearLayoutLoaderCache() {
    cache.removeAll()
}

/// Cache for previously loaded layouts
private var cache = [URL: Layout]()
private let queue = DispatchQueue(label: "com.Layout.LayoutLoader")
private var reloadLock = 0

private extension Layout {
    /// Merges the contents of the specified layout into this one
    /// Will fail if the layout class is not a subclass of this one
    func merged(with layout: Layout) throws -> Layout {
        if let path = xmlPath {
            throw LayoutError("Cannot extend \(className) template until content for \(path) has been loaded.")
        }
        let newClass: AnyClass = try layout.getClass()
        let oldClass: AnyClass = try getClass()
        guard newClass.isSubclass(of: oldClass) else {
            throw LayoutError("Cannot replace \(oldClass) with \(newClass)")
        }
        var expressions = self.expressions
        for (key, value) in layout.expressions {
            expressions[key] = value
        }
        var parameters = self.parameters
        for (key, value) in layout.parameters { // TODO: what about collisions?
            parameters[key] = value
        }
        var macros = self.macros
        for (key, value) in layout.macros { // TODO: what about collisions?
            macros[key] = value
        }
        let result = Layout(
            className: layout.className,
            id: layout.id ?? id,
            expressions: expressions,
            parameters: parameters,
            macros: macros,
            children: children,
            body: layout.body ?? body,
            xmlPath: layout.xmlPath,
            templatePath: templatePath,
            childrenTagIndex: childrenTagIndex,
            relativePath: layout.relativePath, // TODO: is this correct?
            rootURL: rootURL
        )
        return insertChildren(layout.children, into: result)
    }

    /// Insert children into hierarchy
    private func insertChildren(_ children: [Layout], into layout: Layout) -> Layout {
        func _insertChildren(_ children: [Layout], into layout: inout Layout) -> Bool {
            if let index = layout.childrenTagIndex {
                layout.children.insert(contentsOf: children, at: index)
                return true
            }
            for (index, var child) in layout.children.enumerated() {
                if _insertChildren(children, into: &child) {
                    layout.children[index] = child
                    return true
                }
            }
            return false
        }
        var layout = layout
        if !_insertChildren(children, into: &layout) {
            layout.children += children
        }
        return layout
    }

    /// Recursively load all nested layout templates
    func processTemplates(completion: @escaping (Layout?, LayoutError?) -> Void) {
        var result = self
        var error: LayoutError?
        var requestCount = 1 // Offset to 1 initially to prevent premature completion
        func didComplete() {
            requestCount -= 1
            if requestCount == 0 {
                completion(error == nil ? result : nil, error)
            }
        }
        for (index, child) in children.enumerated() {
            requestCount += 1
            child.processTemplates { layout, _error in
                if _error != nil {
                    error = _error
                } else if let layout = layout {
                    result.children[index] = layout
                }
                didComplete()
            }
        }
        if let templatePath = templatePath {
            requestCount += 1
            LayoutLoader().loadLayout(
                withContentsOfURL: urlFromString(templatePath, relativeTo: rootURL),
                relativeTo: relativePath
            ) { layout, _error in
                if _error != nil {
                    error = _error
                } else if let layout = layout {
                    do {
                        result = try layout.merged(with: result)
                    } catch let _error {
                        error = LayoutError(_error)
                    }
                }
                didComplete()
            }
        }
        didComplete()
    }
}

/// API for loading a layout XML file
class LayoutLoader {
    private var _originalURL: URL!
    private var _xmlURL: URL!
    private var _projectDirectory: URL?
    private var _dataTask: URLSessionDataTask?
    private var _state: Any = ()
    private var _constants: [String: Any] = [:]
    private var _strings: [String: String]?

    /// Used for protecting operations that must not be interrupted by a reload.
    /// Any reload attempts that happen inside the block will be ignored
    static func atomic<T>(_ protected: () throws -> T) rethrows -> T {
        queue.sync { reloadLock += 1 }
        defer { queue.sync { reloadLock -= 1 } }
        return try protected()
    }

    // MARK: LayoutNode loading

    /// Loads a named XML layout file from the app resources folder
    public func loadLayoutNode(
        named: String,
        bundle: Bundle = Bundle.main,
        relativeTo: String = #file,
        state: Any = (),
        constants: [String: Any] = [:]
    ) throws -> LayoutNode {
        _state = state
        _constants = constants

        let layout = try loadLayout(
            named: named,
            bundle: bundle,
            relativeTo: relativeTo
        )
        return try LayoutNode(
            layout: layout,
            state: state,
            constants: constants
        )
    }

    /// Loads a local or remote XML layout file with the specified URL
    public func loadLayoutNode(
        withContentsOfURL xmlURL: URL,
        relativeTo: String? = #file,
        state: Any = (),
        constants: [String: Any] = [:],
        completion: @escaping LayoutLoaderCallback
    ) {
        _state = state
        _constants = constants

        loadLayout(
            withContentsOfURL: xmlURL,
            relativeTo: relativeTo,
            completion: { [weak self] layout, error in
                self?._state = state
                self?._constants = constants
                do {
                    guard let layout = layout else {
                        if let error = error {
                            throw error
                        }
                        return
                    }
                    try completion(LayoutNode(
                        layout: layout,
                        state: state,
                        constants: constants
                    ), nil)
                } catch {
                    completion(nil, LayoutError(error))
                }
            }
        )
    }

    /// Reloads the most recently loaded XML layout file
    public func reloadLayoutNode(withCompletion completion: @escaping LayoutLoaderCallback) {
        guard let xmlURL = _originalURL, _dataTask == nil, queue.sync(execute: {
            guard reloadLock == 0 else { return false }
            cache.removeAll()
            return true
        }) else {
            completion(nil, nil)
            return
        }
        loadLayoutNode(
            withContentsOfURL: xmlURL,
            relativeTo: nil,
            state: _state,
            constants: _constants,
            completion: completion
        )
    }

    // MARK: Layout loading

    public func loadLayout(
        named: String,
        bundle: Bundle = Bundle.main,
        relativeTo: String = #file
    ) throws -> Layout {
        assert(Thread.isMainThread)
        guard let xmlURL = bundle.url(forResource: named, withExtension: nil) ??
            bundle.url(forResource: named, withExtension: "xml")
        else {
            throw LayoutError.message("No layout XML file found for \(named)")
        }
        var _layout: Layout?
        var _error: Error?
        loadLayout(
            withContentsOfURL: xmlURL,
            relativeTo: relativeTo
        ) { layout, error in
            _layout = layout
            _error = error
        }
        if let error = _error {
            throw error
        }
        guard let layout = _layout else {
            throw LayoutError("Unable to synchronously load \(named). It may depend on a remote template. Try using loadLayout(withContentsOfURL:) instead")
        }
        return layout
    }

    public func loadLayout(
        withContentsOfURL xmlURL: URL,
        relativeTo: String? = #file,
        completion: @escaping (Layout?, LayoutError?) -> Void
    ) {
        _dataTask?.cancel()
        _dataTask = nil
        _originalURL = xmlURL.standardizedFileURL
        _xmlURL = _originalURL
        _strings = nil

        func processLayoutData(_ data: Data) throws {
            assert(Thread.isMainThread) // TODO: can we parse XML in the background instead?
            do {
                let layout = try Layout(xmlData: data, url: _xmlURL, relativeTo: relativeTo)
                queue.async { cache[self._xmlURL] = layout }
                layout.processTemplates(completion: completion)
            } catch {
                throw LayoutError(error, in: xmlURL.lastPathComponent)
            }
        }

        // If it's a bundle resource url, replace with equivalent source url
        if xmlURL.isFileURL {
            let xmlURL = xmlURL.standardizedFileURL
            let bundlePath = Bundle.main.bundleURL.absoluteString
            if xmlURL.absoluteString.hasPrefix(bundlePath) {
                if _projectDirectory == nil, let relativeTo = relativeTo,
                   let projectDirectory = findProjectDirectory(at: relativeTo)
                {
                    _projectDirectory = projectDirectory
                }
                if let projectDirectory = _projectDirectory {
                    let xmlPath = xmlURL.absoluteString
                    var parts = xmlPath[bundlePath.endIndex ..< xmlPath.endIndex].components(separatedBy: "/")
                    for (i, part) in parts.enumerated().reversed() {
                        if part.hasSuffix(".bundle") {
                            parts.removeFirst(i + 1)
                            break
                        }
                    }
                    let path = parts.joined(separator: "/")
                    do {
                        _xmlURL = try findSourceURL(forRelativePath: path, in: projectDirectory)
                    } catch {
                        completion(nil, LayoutError(error))
                        return
                    }
                }
            }
        }

        // Check cache
        var layout: Layout?
        queue.sync { layout = cache[_xmlURL] }
        if let layout = layout {
            layout.processTemplates(completion: completion)
            return
        }

        // Load synchronously if it's a local file and we're on the main thread already
        if _xmlURL.isFileURL, Thread.isMainThread {
            do {
                let data = try Data(contentsOf: _xmlURL)
                try processLayoutData(data)
            } catch {
                completion(nil, LayoutError(error))
            }
            return
        }

        // Load asynchronously
        let xmlURL = _xmlURL!
        _dataTask = URLSession.shared.dataTask(with: xmlURL) { data, _, error in
            DispatchQueue.main.async {
                self._dataTask = nil
                if self._xmlURL != xmlURL {
                    return // Must have been cancelled
                }
                do {
                    guard let data = data else {
                        if let error = error {
                            throw error
                        }
                        return
                    }
                    try processLayoutData(data)
                } catch {
                    completion(nil, LayoutError(error))
                }
            }
        }
        _dataTask?.resume()
    }

    // MARK: String loading

    public func loadLocalizedStrings() throws -> [String: String] {
        if let strings = _strings {
            return strings
        }
        var path = "Localizable.strings"
        let localizedPath = Bundle.main.path(forResource: "Localizable", ofType: "strings")
        if let resourcePath = Bundle.main.resourcePath, let localizedPath = localizedPath {
            path = String(localizedPath[resourcePath.endIndex ..< localizedPath.endIndex])
        }
        if let projectDirectory = _projectDirectory {
            let url = try findSourceURL(forRelativePath: path, in: projectDirectory)
            _strings = NSDictionary(contentsOf: url) as? [String: String] ?? [:]
            return _strings!
        }
        if let stringsFile = localizedPath {
            _strings = NSDictionary(contentsOfFile: stringsFile) as? [String: String] ?? [:]
            return _strings!
        }
        return [:]
    }

    // MARK: Internal APIs exposed for LayoutConsole

    func setSourceURL(_ sourceURL: URL, for path: String) {
        _setSourceURL(sourceURL, for: path)
    }

    func clearSourceURLs() {
        _clearSourceURLs()
    }

    // MARK: Internal APIs exposed for testing

    func findProjectDirectory(at path: String) -> URL? {
        return _findProjectDirectory(at: path)
    }

    func findSourceURL(
        forRelativePath path: String,
        in directory: URL,
        ignoring: [URL] = [],
        usingCache: Bool = true
    ) throws -> URL {
        guard let url = try _findSourceURL(
            forRelativePath: path,
            in: directory,
            ignoring: ignoring,
            usingCache: usingCache
        ) else {
            throw LayoutError.message("Unable to locate source file for \(path)")
        }
        return url
    }
}

#if arch(i386) || arch(x86_64)

    // MARK: Only applicable when running in the simulator

    private var layoutSettings: [String: Any] {
        get { return UserDefaults.standard.dictionary(forKey: "com.Layout") ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "com.Layout") }
    }

    private var _projectDirectory: URL? {
        didSet {
            let path = _projectDirectory?.path
            if path != layoutSettings["projectDirectory"] as? String {
                sourcePaths.removeAll()
                layoutSettings["projectDirectory"] = path
            }
        }
    }

    private var _sourcePaths: [String: String] = layoutSettings["sourcePaths"] as? [String: String] ?? [:]

    private var sourcePaths: [String: String] {
        get { return _sourcePaths }
        set {
            _sourcePaths = newValue
            layoutSettings["sourcePaths"] = _sourcePaths
        }
    }

    private func _findProjectDirectory(at path: String) -> URL? {
        var url = URL(fileURLWithPath: path).standardizedFileURL
        if let projectDirectory = _projectDirectory,
           url.absoluteString.hasPrefix(projectDirectory.absoluteString)
        {
            return projectDirectory
        }
        if !url.hasDirectoryPath {
            url.deleteLastPathComponent()
        }
        while !url.absoluteString.isEmpty {
            if let files = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            ), files.contains(where: { ["xcodeproj", "xcworkspace"].contains($0.pathExtension) }) {
                return url
            }
            url.deleteLastPathComponent()
        }
        return nil
    }

    private func _findSourceURL(
        forRelativePath path: String,
        in directory: URL,
        ignoring: [URL],
        usingCache: Bool
    ) throws -> URL? {
        if let filePath = sourcePaths[path], FileManager.default.fileExists(atPath: filePath) {
            let url = URL(fileURLWithPath: filePath).standardizedFileURL
            if url.absoluteString.hasPrefix(directory.absoluteString) {
                return url
            }
        }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return nil
        }
        var ignoring = ignoring
        if files.contains(layoutIgnoreFile) {
            ignoring += try LayoutError.wrap {
                try parseIgnoreFile(directory.appendingPathComponent(layoutIgnoreFile))
            }
        }
        var parts = path.components(separatedBy: "/")
        if parts[0] == "" {
            parts.removeFirst()
        }
        var results = [URL]()
        for file in files where
            file != "build" && !file.hasPrefix(".") && ![
                ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
            ].contains(where: { file.hasSuffix($0) })
        {
            let directory = directory.appendingPathComponent(file)
            if ignoring.contains(directory) {
                continue
            }
            if file == parts[0] {
                if parts.count == 1 {
                    results.append(directory) // Not actually a directory
                    continue
                }
                try _findSourceURL(
                    forRelativePath: parts.dropFirst().joined(separator: "/"),
                    in: directory,
                    ignoring: ignoring,
                    usingCache: false
                ).map {
                    results.append($0)
                }
            }
            try _findSourceURL(
                forRelativePath: path,
                in: directory,
                ignoring: ignoring,
                usingCache: false
            ).map {
                results.append($0)
            }
        }
        guard results.count <= 1 else {
            throw LayoutError.multipleMatches(results, for: path)
        }
        if usingCache, let url = results.first {
            _setSourceURL(url, for: path)
        }
        return results.first
    }

    private func _setSourceURL(_ sourceURL: URL, for path: String) {
        guard sourceURL.isFileURL else {
            preconditionFailure()
        }
        sourcePaths[path] = sourceURL.path
    }

    private func _clearSourceURLs() {
        sourcePaths.removeAll()
    }

#else

    private func _findProjectDirectory(at _: String) -> URL? { return nil }
    private func _findSourceURL(forRelativePath _: String, in _: URL, ignoring _: [URL], usingCache _: Bool) throws -> URL? { return nil }
    private func _setSourceURL(_: URL, for _: String) {}
    private func _clearSourceURLs() {}

#endif
