import SwiftUI
import UniformTypeIdentifiers
import CoreGraphics

struct ContentView: View {
    @State private var psdFiles: [URL] = []
    @State private var outputDirectory: URL? = nil
    @State private var isProcessing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showOverwriteAlert: Bool = false
    @State private var currentFileToOverwrite: URL? = nil
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        VStack {
            
            Image("converter_logo_gray")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top)
                .frame(height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
            
            Text("PSD to PNG Converter")
                .font(.title)
                .padding()
            
            Button(action: {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = true
                panel.canChooseDirectories = false
                panel.allowedContentTypes = [UTType(filenameExtension: "psd")!]
                panel.begin { response in
                    if response == .OK {
                        self.psdFiles = panel.urls
                    }
                }
            }) {
                Text("Select PSD Files")
                    .padding()
                    .frame(width: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                   
            }
            
            
            if !psdFiles.isEmpty {
                List(psdFiles, id: \ .self) { url in
                    Text(url.lastPathComponent)
                }
            }
            
            Button(action: {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.begin { response in
                    if response == .OK {
                        self.outputDirectory = panel.url
                    }
                }
            }) {
                Text("Select Output Directory")
                    .padding()
                    .frame(width: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
            
            }
            .disabled(psdFiles.isEmpty)
            
            if let outputDirectory = outputDirectory {
                Text("Output Directory: \(outputDirectory.path)")
                    .padding()
            }
            
            Button(action: {
                convertFiles()
            }) {
                Text("Convert to PNG")
                    .padding()
                    .frame(width: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                
            }
           // .background(Color.blue)
            
            .disabled(psdFiles.isEmpty || outputDirectory == nil || isProcessing)
            
            if isProcessing {
                ProgressView()
                    .padding()
            }
            
            Image("ben")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 30.0)
                .frame(height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
          
            
            Link("@haythuyt", destination: URL(string: "https://x.com/haythuyt")!)
                .padding(.bottom)
                .font(.body)
                .buttonStyle(PlainButtonStyle())
            
               
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Conversion Completed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showOverwriteAlert) {
            Alert(
                title: Text("File Exists"),
                message: Text("A file with the same name already exists. Do you want to overwrite it?"),
                primaryButton: .destructive(Text("Overwrite")) {
                    if let fileToOverwrite = currentFileToOverwrite {
                        overwriteFile(fileToOverwrite)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("All files have been successfully converted."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func convertFiles() {
        guard let outputDirectory = outputDirectory else { return }
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            for psdFile in psdFiles {
                let outputURL = outputDirectory.appendingPathComponent(psdFile.deletingPathExtension().lastPathComponent).appendingPathExtension("png")
                
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    DispatchQueue.main.async {
                        self.currentFileToOverwrite = outputURL
                        self.showOverwriteAlert = true
                    }
                    // Bekle ve kullanıcıdan yanıt alana kadar diğer dosyaları işlemeyi durdur
                    while self.showOverwriteAlert { }
                } else {
                    self.savePNG(from: psdFile, to: outputURL)
                }
            }
            DispatchQueue.main.async {
                isProcessing = false
                alertMessage = "Converted \(psdFiles.count) files successfully."
                showAlert = true
                showSuccessAlert = true
            }
        }
    }
    
    private func savePNG(from psdFile: URL, to outputURL: URL) {
        if let cgImage = self.createCGImageFromPSD(fileURL: psdFile) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: outputURL)
                } catch {
                    DispatchQueue.main.async {
                        alertMessage = "Failed to save PNG for \(psdFile.lastPathComponent): \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }
        }
    }
    
    private func overwriteFile(_ outputURL: URL) {
        if let psdFile = psdFiles.first(where: { $0.deletingPathExtension().lastPathComponent == outputURL.deletingPathExtension().lastPathComponent }) {
            savePNG(from: psdFile, to: outputURL)
        }
        currentFileToOverwrite = nil
        showOverwriteAlert = false
    }
    
    private func createCGImageFromPSD(fileURL: URL) -> CGImage? {
        guard let provider = CGDataProvider(url: fileURL as CFURL),
              let imageSource = CGImageSourceCreateWithDataProvider(provider, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }
}

#Preview {
    ContentView()
}
