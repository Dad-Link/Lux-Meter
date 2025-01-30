import SwiftUI

struct AboutLuxView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // **Title**
                Text("About Lux")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)
                
                // **What is Lux?**
                LuxSection(title: "What is Lux?", content: """
Lux is the unit of measurement for illuminance, which quantifies the amount of visible light falling on a surface. It tells us how **bright or dim a space is** in terms of human vision.

💡 **In simple terms:** The higher the lux, the brighter the light!  
""")
                
                // **How is Lux Measured?**
                LuxSection(title: "How is Lux Measured?", content: """
Lux is calculated as **lumens per square meter**:

👉 **1 lux = 1 lumen/m²**  

For example, if a **1,000-lumen light bulb** illuminates an area of **10 square meters**, the resulting illuminance is:

**100 lux** = 1,000 lumens ÷ 10m²
""")

                // **Examples of Lux Levels**
                LuxSection(title: "Real-World Lux Examples", content: """
Here are some common light sources and their lux levels:

🌞 **Full daylight** – 10,000 to 25,000 lux  
🌥 **Overcast daylight** – 1,000 lux  
💼 **Office lighting** – 300 to 500 lux  
📚 **Reading lamp** – 400 to 600 lux  
🌇 **Sunrise/Sunset** – 10 to 100 lux  
🌙 **Full moon** – 0.1 lux  
""")

                // **Ideal Lux Levels for Different Activities**
                LuxSection(title: "Ideal Lux Readings Per Activity", content: """
Different activities require different amounts of light for comfort and safety:

🏡 **Living Room / Lounge** – 100 to 300 lux  
📖 **Reading / Studying** – 400 to 600 lux  
💻 **Computer Work / Office** – 300 to 500 lux  
🛠 **Workshops / DIY tasks** – 750 to 1,000 lux  
🌿 **Indoor Plants / Horticulture** – 2,000+ lux  
📸 **Photography Studio** – 5,000+ lux  
""")

                // **Why is Lux Important?**
                LuxSection(title: "Why is Lux Important?", content: """
Measuring lux levels helps in various industries and activities:

📷 **Photography & Videography** – Ensures correct lighting for clear images.  
👓 **Workplace & Eye Health** – Reduces eye strain and fatigue.  
🌱 **Horticulture & Gardening** – Helps plants get enough light for growth.  
🏗 **Architecture & Interior Design** – Creates well-lit, comfortable spaces.  
🚸 **Safety & Regulations** – Ensures proper lighting in workplaces and public areas.  
""")

                // **How to Use a Lux Meter?**
                LuxSection(title: "How to Use a Lux Meter?", content: """
A **lux meter** is a simple device that helps measure light intensity.

To measure lux:  
✅ **Point the sensor toward the light source**  
✅ **Hold the device steady and wait for a reading**  
✅ **Compare the results with recommended lux levels**  

Our **Lux Meter App** lets you **measure light using your phone's camera**!
""")

                // **Read More Link**
                Link(destination: URL(string: "https://dadlink.co.uk/pages/lux-guide")!) {
                    Text("Read More About Lux Measurement")
                        .font(.headline)
                        .foregroundColor(.gold)
                        .underline()
                        .padding(.top, 5)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("About Lux")

        // **Powered By Footer**
        .safeAreaInset(edge: .bottom) {
            VStack {
                Link(destination: URL(string: "https://dadlink.co.uk")!) {
                    Text("Powered by DadLink Technologies Limited")
                        .font(.footnote)
                        .foregroundColor(.gold)
                        .underline()
                        .padding(.bottom, 5)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }
}

// MARK: - **Reusable Section Component**
struct LuxSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.gold)
                .padding(.top, 5)
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 5)
    }
}

