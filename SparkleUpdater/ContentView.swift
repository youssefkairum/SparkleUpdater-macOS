//
//  ContentView.swift
//  SparkleUpdater
//
//  Created by Youssef Keram on 12/6/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation
import Combine

// MARK: - 1. DATA MODELS (Persistence)

struct Project: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = "New App"
    var appcastPath: String = ""
    var baseURL: String = "https://example.com/downloads/"
    
    // New Fields for Appcast Header Customization
    var appcastTitle: String = ""
    var appcastDescription: String = ""
    var appcastLanguage: String = "en"
}

// MARK: - 2. VIEW MODEL

class AppViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProjectID: UUID?
    
    private let saveKey = "SparkleCommander_Projects_V3"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = decoded
        }
        
        if projects.isEmpty {
            var new = Project(name: "My First App")
            // Set initial defaults for customization
            new.appcastTitle = "My First App Updates"
            new.appcastDescription = "The latest release information for My First App."
            
            projects.append(new)
            selectedProjectID = new.id
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addProject() {
        var new = Project(name: "New Project \(projects.count + 1)")
        // Set initial defaults for customization
        new.appcastTitle = "\(new.name) Updates"
        new.appcastDescription = "The latest release information for \(new.name)."
        
        projects.append(new)
        selectedProjectID = new.id
        save()
    }
    
    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        if let nextID = projects.first?.id {
            selectedProjectID = nextID
        } else {
            selectedProjectID = nil
        }
        save()
    }
}

// MARK: - 3. MAIN NAVIGATION VIEW

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR
            List(selection: $viewModel.selectedProjectID) {
                Section(header: Text("YOUR APPS")) {
                    ForEach($viewModel.projects) { $project in
                        NavigationLink(value: project.id) {
                            TextField("App Name", text: $project.name)
                                .textFieldStyle(.plain)
                                .onSubmit { viewModel.save() }
                        }
                        .contextMenu {
                            Button("Delete") { viewModel.deleteProject(id: project.id) }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.addProject) {
                        Label("Add App", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // DETAIL VIEW
            if let selectedID = viewModel.selectedProjectID,
               let index = viewModel.projects.firstIndex(where: { $0.id == selectedID }) {
                
                ProjectDetailView(project: $viewModel.projects[index])
                    .onDisappear { viewModel.save() }
            } else {
                Text("Select an App to Manage or click '+' to create a new project.")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 900, minHeight: 650)
    }
}

// MARK: - 4. THE PROJECT EDITOR (The Core Logic)

struct ProjectDetailView: View {
    @Binding var project: Project
    
    // Transient State (Not saved to disk)
    @State private var version: String = ""
    @State private var shortVersion: String = ""
    @State private var fileSize: String = ""
    @State private var signature: String = ""
    @State private var releaseNotes: String = "<ul>\n<li>Bug fixes and performance improvements.</li>\n</ul>"
    @State private var isCritical: Bool = false
    @State private var statusMessage: String = "Ready to publish."
    @State private var statusColor: Color = .secondary
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // TOP CONFIGURATION BAR
            VStack(alignment: .leading, spacing: 15) {
                Text(project.name)
                    .font(.largeTitle).bold()
                
                GroupBox(label: Label("Paths & URLs", systemImage: "link")) {
                    Grid(alignment: .leading, verticalSpacing: 10) {
                        GridRow {
                            Text("Appcast XML Path:")
                            HStack {
                                TextField("Full path where appcast.xml should be saved...", text: $project.appcastPath)
                                    .textFieldStyle(.roundedBorder)
                                Button("Browse") { selectAppcast() }
                            }
                        }
                        GridRow {
                            Text("Download Base URL:")
                            TextField("https://your-site.com/downloads/", text: $project.baseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }
                
                // MARK: - APPCAST CUSTOMIZATION SECTION
                GroupBox(label: Label("Appcast Header Customization", systemImage: "doc.text.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Title (e.g., App Name Updates)", text: $project.appcastTitle)
                        TextField("Language Code (e.g., en, es, ja)", text: $project.appcastLanguage)
                            .frame(maxWidth: 150, alignment: .leading)
                        
                        TextEditor(text: $project.appcastDescription)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 50)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.2)))
                            .padding(.top, 4)
                    }
                    .padding(8)
                }
                
                HStack {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("The signature tool is bundled. No separate installation is needed.")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // MAIN WORKSPACE
            HStack(spacing: 0) {
                // LEFT: Release Details
                Form {
                    Section("New Release Info") {
                        Toggle("Force Mandatory Update", isOn: $isCritical)
                            .toggleStyle(.switch)
                            .padding(.vertical, 5)
                        
                        VStack(alignment: .leading) {
                            Text("Release Notes (HTML):")
                                .font(.caption).foregroundColor(.secondary)
                            TextEditor(text: $releaseNotes)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 150)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.2)))
                        }
                    }
                    
                    Section("Detected/Generated Information") {
                        LabeledContent("Version", value: version.isEmpty ? "--" : version)
                        LabeledContent("Size", value: fileSize.isEmpty ? "--" : "\(fileSize) bytes")
                        LabeledContent("Signature Status", value: signature.isEmpty ? "--" : "Successfully Generated")
                            .foregroundColor(signature.isEmpty ? .secondary : .green)
                    }
                }
                .padding()
                .frame(maxWidth: 450)
                
                Divider()
                
                // RIGHT: Action Zone
                VStack(spacing: 30) {
                    Spacer()
                    
                    if isProcessing {
                        ProgressView("Processing Build...")
                            .scaleEffect(1.5)
                    } else {
                        Button(action: selectUpdateFile) {
                            VStack(spacing: 15) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 45))
                                    .foregroundStyle(.blue, .blue.opacity(0.3))
                                Text("DROP BUILD HERE")
                                    .font(.title2).bold()
                                Text("Select .zip or .dmg to Sign & Publish")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .frame(width: 280, height: 200)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Logger
                    ScrollView {
                        Text(statusMessage)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(statusColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 120)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
    
    // MARK: - LOGIC
    func selectAppcast() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.xml]
        panel.nameFieldStringValue = "appcast.xml"
        
        if panel.runModal() == .OK {
            project.appcastPath = panel.url?.path ?? ""
        }
    }
    
    func selectUpdateFile() {
        guard !project.appcastPath.isEmpty else {
            setStatus("❌ Please set the Appcast XML path first. Use 'Browse' to select where the file should be saved or created.", color: .red)
            return
        }
        guard !project.baseURL.isEmpty && (project.baseURL.hasPrefix("http://") || project.baseURL.hasPrefix("https://")) else {
            setStatus("❌ Please set a valid Download URL.", color: .red)
            return
        }
        guard !project.appcastTitle.isEmpty else {
            setStatus("❌ Please provide an Appcast Header Title.", color: .red)
            return
        }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip, .diskImage]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            runAutomation(fileURL: url)
        }
    }
    
    func runAutomation(fileURL: URL) {
        isProcessing = true
        setStatus("1. Analyzing file...", color: .white)
        
        // 1. Get File Size
        do {
            let res = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            self.fileSize = String(res.fileSize ?? 0)
        } catch {
            setStatus("❌ Error reading file size.", color: .red)
            isProcessing = false; return
        }
        
        // 2. Parse Version from Filename (e.g., App_1.2.zip)
        let filename = fileURL.lastPathComponent
        let components = filename.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        self.version = components.first ?? "1.0"
        self.shortVersion = self.version
        
        // 3. Generate Signature (Background)
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async { setStatus("2. Generating EdDSA Signature...", color: .yellow) }
            
            let sig = ShellRunner.runBundledSignature(filePath: fileURL.path)
            
            DispatchQueue.main.async {
                if sig.lowercased().contains("error") || sig.isEmpty {
                    setStatus("❌ Signature Failed: Ensure your signing key is in Keychain.", color: .red)
                    isProcessing = false
                    return
                }
                
                self.signature = sig
                setStatus("3. Updating Appcast XML...", color: .yellow)
                
                // 4. Generate XML & Inject
                let newItem = generateXML(filename: filename)
                let result = XMLInjector.updateAppcast(for: project, with: newItem)
                
                if result.contains("Success") {
                    setStatus("✅ DONE! \(result)", color: .green)
                } else {
                    setStatus("❌ \(result)", color: .red)
                }
                
                isProcessing = false
            }
        }
    }
    
    func generateXML(filename: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: Date())
        
        let criticalTag = isCritical ? "\n            <sparkle:criticalUpdate sparkle:version=\"\(version)\" />" : ""
        let fullURL = (project.baseURL.hasSuffix("/") ? project.baseURL : project.baseURL + "/") + filename
        
        return """
        <item>
            <title>Version \(shortVersion)</title>
            <pubDate>\(dateString)</pubDate>
            <sparkle:releaseNotesHTML><![CDATA[\(releaseNotes)]]></sparkle:releaseNotesHTML>
            <enclosure url="\(fullURL)"
                       sparkle:version="\(version)"
                       sparkle:shortVersionString="\(shortVersion)"
                       sparkle:edSignature="\(signature)"
                       length="\(fileSize)"
                       type="application/octet-stream" />\(criticalTag)
        </item>
        """
    }
    
    func setStatus(_ msg: String, color: Color) {
        statusMessage = msg
        statusColor = color
    }
}

// MARK: - 5. HELPERS (The Engine)

struct ShellRunner {
    static func runBundledSignature(filePath: String) -> String {
        
        guard let binaryPath = Bundle.main.path(forResource: "sign_update", ofType: nil) else {
            return "Error: 'sign_update' not found in Bundle."
        }
        
        ensureExecutable(path: binaryPath)
        
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: binaryPath)
        task.arguments = [filePath]
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        if let frameworksPath = Bundle.main.privateFrameworksPath {
            task.environment = ["DYLD_FRAMEWORK_PATH": frameworksPath]
        }
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let err = String(data: errorData, encoding: .utf8), !err.isEmpty {
                return "Error from tool: \(err)"
            }
        } catch {
            return "System Error: \(error.localizedDescription)"
        }
        return "Unknown Error"
    }
    
    private static func ensureExecutable(path: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/chmod")
        task.arguments = ["+x", path]
        try? task.run()
        task.waitUntilExit()
    }
}

struct XMLInjector {
    
    // Generates the full RSS/Appcast wrapper XML using custom fields
    private static func generateFullAppcast(for project: Project, itemXML: String) -> String {
        // Use custom fields
        let title = project.appcastTitle.isEmpty ? "\(project.name) Updates" : project.appcastTitle
        let description = project.appcastDescription.isEmpty ? "The latest release information for \(project.name)." : project.appcastDescription
        let language = project.appcastLanguage
        
        // Link to the appcast file itself on the server
        let link = (project.baseURL.hasSuffix("/") ? project.baseURL : project.baseURL + "/") + "appcast.xml"

        return """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.sparkle-project.org/2014/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom">
            <channel>
                <title>\(title)</title>
                <link>\(link)</link>
                <description>\(description)</description>
                <language>\(language)</language>
                <atom:link rel="enclosure" type="application/rss+xml" href="\(link)" />
                
                <!-- BEGIN RELEASE ITEMS -->
                
                \(itemXML)
                
                <!-- END RELEASE ITEMS -->
            </channel>
        </rss>
        """
    }

    /// Reads, injects, or creates the appcast.xml file.
    static func updateAppcast(for project: Project, with newItemXML: String) -> String {
        let path = project.appcastPath
        let fileURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: path) {
                // CASE 1: File Exists (Standard Injection)
                var content = try String(contentsOf: fileURL, encoding: .utf8)
                
                // Backup
                let backupURL = fileURL.appendingPathExtension("bak")
                try content.write(to: backupURL, atomically: true, encoding: .utf8)
                
                // Inject
                if let range = content.range(of: "<item>") {
                    content.insert(contentsOf: "\n" + newItemXML + "\n", at: range.lowerBound)
                } else if let range = content.range(of: "</channel>") {
                    content.insert(contentsOf: "\n" + newItemXML + "\n", at: range.lowerBound)
                } else {
                    return "Error: Invalid appcast format (missing <item> or <channel> tags)."
                }
                
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                return "Success! Existing Appcast updated and backup created."
                
            } else {
                // CASE 2: File Does NOT Exist (Generate New File)
                let newContent = generateFullAppcast(for: project, itemXML: newItemXML)
                
                // Create directory if needed
                let directoryURL = fileURL.deletingLastPathComponent()
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                
                // Write the complete new structure to disk
                try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
                
                return "Success! New Appcast file created and initial release added."
            }
        } catch {
            return "File Operation Error: \(error.localizedDescription)"
        }
    }
}
