import SwiftUI

struct AboutLuxView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About Lux")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("What is Lux?")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
Lux is the unit of measurement for illuminance, which quantifies the amount of visible light that falls on a surface. It measures the intensity of light as perceived by the human eye, taking into account the sensitivity of the eye to different wavelengths of light.
""")
                
                Text("How is Lux Measured?")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
Lux is calculated as lumens per square meter. For example, if a light source emits 1,000 lumens and evenly illuminates an area of 10 square meters, the illuminance is 100 lux.

- 1 lux = 1 lumen/m²
- A lux meter is used to measure this illuminance in real-world environments.
""")
                
                Text("Examples of Lux Levels")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
- Full daylight: 10,000–25,000 lux
- Overcast daylight: 1,000 lux
- Typical office lighting: 300–500 lux
- Sunrise or sunset: 10–100 lux
- Full moon: 0.1 lux
""")
                
                Text("Why is Lux Important?")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
Understanding and measuring lux levels is crucial in various fields, such as:

- **Photography and Videography**: Ensuring proper exposure for capturing images.
- **Workplace Safety**: Providing adequate lighting to reduce eye strain and improve productivity.
- **Horticulture**: Monitoring light levels for optimal plant growth.
- **Architecture**: Designing spaces with sufficient natural and artificial light.
""")
                
                Text("Using Lux Meters")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
Lux meters are devices that measure illuminance accurately. They are commonly used by professionals and enthusiasts to evaluate light conditions in various environments.
""")
            }
            .padding()
        }
        .navigationTitle("About Lux")
    }
}
