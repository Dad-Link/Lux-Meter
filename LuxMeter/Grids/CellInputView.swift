import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit
import UIKit

// MARK: - CellInputView
struct CellInputView: View {
    @Binding var selectedCell: (row: Int, column: Int)?
    @Binding var lightReference: String?
    @Binding var luxValue: String
    @Binding var showSaveSuccess: Bool
    @Binding var luxGrid: [String: LuxCell]
    var gridId: String
    var onSave: (Int, Int) -> Void
    var onDismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Selected Cell: [\(selectedCell?.row ?? 0), \(selectedCell?.column ?? 0)]")
                .font(.headline)
                .foregroundColor(.gold)
            
            TextField("Enter Light Reference", text: Binding(
                get: { lightReference ?? "" },
                set: { lightReference = $0 }
            ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Enter Lux Value", text: $luxValue)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Save Button (Stores in Firebase)
            Button(action: {
                if let cell = selectedCell {
                    onSave(cell.row, cell.column)
                    showSaveSuccess = true
                    onDismiss()
                }
            }) {
                HStack {
                    Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    Text(showSaveSuccess ? "✅ Saved" : "Save")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gold)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 5)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset.height = gesture.translation.height
                }
                .onEnded { _ in
                    if dragOffset.height > 100 {
                        onDismiss()
                    }
                    dragOffset = .zero
                }
        )
    }
}
