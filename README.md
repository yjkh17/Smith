# Smith 🧠

**Your Omniscient AI System Assistant - Know Everything About Your Mac**

Smith is an intelligent macOS system assistant that monitors, analyzes, and understands every aspect of your Mac. Built with Apple's Foundation Models framework, Smith provides comprehensive system knowledge and AI-powered insights for optimal macOS experience.

## 🎯 **Ultimate Goal**

**Complete Mac Awareness** - Smith's mission is to know everything about your Mac's current state, so when you ask any question about system status, performance, files, applications, or optimization, it can provide accurate, contextual, and actionable answers.

## ✨ Features

### 🖥️ **Comprehensive System Monitoring**
- **CPU Performance** - Real-time usage, temperature, core activity, and process monitoring
  - Tracks usage across all logical cores, so overall percentages may exceed 100%
- **Memory Management** - RAM usage, pressure, swap activity, and optimization
- **Battery Health** - Power consumption, charging cycles, health metrics, and efficiency tips
- **Storage Analysis** - Disk usage, file types, large files, and cleanup opportunities
- **Network Activity** - Bandwidth usage, connections, and network health
- **Network Name Detection** - Shows the currently connected network or SSID
- **Current Location** - Determine your approximate location for context-aware insights
- **Thermal Management** - Temperature monitoring and thermal throttling detection
- **Process Intelligence** - Application behavior, resource consumption, and performance impact

### 🤖 **Omniscient AI Assistant**
- **Complete System Knowledge** - Knows current state of all system components
- **Contextual Intelligence** - Understands relationships between system metrics
- **Predictive Analysis** - Anticipates issues before they impact performance
- **Natural Language Interface** - Ask anything about your Mac in plain English
- **Foundation Models** - Powered by Apple's on-device AI (iOS 26/macOS 26)
- **Real-time Insights** - Always up-to-date system understanding

### 🔍 **Deep System Introspection**
- **Application Monitoring** - Track every running app, their resource usage, and behavior
- **File System Intelligence** - Understand file relationships, usage patterns, and optimization
- **Hardware Awareness** - Monitor all hardware components and their health
- **System Configuration** - Track settings, preferences, and system modifications
- **Performance Profiling** - Continuous analysis of system performance patterns
- **Security Monitoring** - Track system security status and potential vulnerabilities

### 🔗 **Universal macOS Integration**
- **Services Menu** - Right-click integration in any app for instant analysis
- **URL Scheme** - `smith://` commands for automation and scripting
- **Quick Actions** - Finder and text selection integration for immediate insights
- **Spotlight Integration** - Search for Smith knowledge system-wide
- **AppleScript Support** - Automation and integration with other tools
- **Terminal Commands** - CLI access to Smith's knowledge base

### 🧠 **Knowledge Domains**

Smith maintains comprehensive knowledge about:

#### **System Performance**
- CPU utilization patterns and bottlenecks
- Memory allocation and efficiency
- Disk I/O performance and optimization
- Network throughput and connectivity
- Graphics performance and acceleration

#### **Application Intelligence**
- Resource consumption by application
- Application startup times and efficiency
- Background processes and their impact
- Application compatibility and conflicts
- Update status and security patches

#### **File System Mastery**
- Storage usage by category and location
- Duplicate files and optimization opportunities
- File access patterns and usage frequency
- Backup status and data protection
- Cache and temporary file management

#### **Hardware Health**
- Component temperatures and thermal management
- Battery health and charging patterns
- Storage device health and lifespan
- Memory integrity and performance
- External device connectivity and performance

#### **Security & Privacy**
- System integrity and security status
- Privacy settings and data protection
- Network security and firewall status
- Application permissions and access
- System vulnerabilities and patches

### 🔒 **Privacy & Performance**
- **On-Device Processing** - All AI processing and data analysis happens locally
- **No Data Transmission** - Your system data never leaves your Mac
- **Privacy First** - Complete respect for user privacy and data security
- **Optimized Performance** - Efficient monitoring with minimal resource impact
- **Real-time Updates** - Continuous learning without affecting system performance

## 🚀 Requirements

- **macOS 26.0+** (Latest)
- **iOS 26.0+** for Foundation Models
- **Apple Intelligence** enabled
- **Apple Silicon Mac** (M1/M2/M3/M4+)
- **16GB RAM** recommended for optimal AI performance
- **Administrative Privileges** for deep system monitoring
- **Full Disk Access** so Smith can analyze system files
- **Microphone & Camera Access** for future voice and diagnostic features

### Required Permissions

Smith requests several macOS permissions on first launch:

- **Full Disk Access** – enables deep file and system monitoring
- **Microphone** – allows upcoming voice command functionality
- **Camera** – used for advanced diagnostics when enabled
- **Notifications** – provides background alerts and status updates
- **Accessibility** – monitors app behavior for optimization suggestions

## 🏁 Getting Started

### Prerequisites

- **macOS 26.0 or later**
- **Xcode 15 or later**

### Building Smith

1. Open `Smith.xcodeproj` in **Xcode 15** or later.
2. In the **Signing & Capabilities** tab for the **Smith** target, enable the **Apple Intelligence** capability. This adds the required `com.apple.developer.apple-intelligence` entitlements found in `Smith/Smith.entitlements`.
3. Select the **Smith** scheme and click **Run** (or press <kbd>⌘R</kbd>) to build and launch the app.

### Build & Run

1. Open `Smith.xcodeproj` in Xcode.
2. Select the **Smith** target from the scheme menu.
3. Click **Run** to build and launch the app.

### LaunchAgent & CLI Options

Smith can run in the background using a LaunchAgent. From the app's **Background Settings** you can install the agent which places
`~/Library/LaunchAgents/com.motherofbrand.Smith.BackgroundMonitor.plist` on your Mac. The agent launches Smith with the following
command‑line options:

- `--background-monitor` &ndash; run the app headlessly for background monitoring
- `--intensity=<minimal|medium|balanced|comprehensive>` &ndash; control monitoring frequency

You can manually load or unload the agent at any time:

```bash
launchctl load ~/Library/LaunchAgents/com.motherofbrand.Smith.BackgroundMonitor.plist
launchctl unload ~/Library/LaunchAgents/com.motherofbrand.Smith.BackgroundMonitor.plist
```

## 🛠️ Architecture

Smith is built with modern Apple technologies for comprehensive system awareness:

- **Foundation Models Framework** - Apple's on-device LLM (iOS 26)
- **SwiftUI** - Native macOS interface with modern design
- **Combine** - Reactive programming for real-time system updates
- **Core System APIs** - Deep integration with macOS internals
- **System Configuration Framework** - Monitor system settings and changes
- **IOKit** - Hardware monitoring and device management
- **Network Framework** - Network activity and performance monitoring
- **Unified Logging** - System log analysis and pattern recognition
- **Endpoint Security** - Security monitoring and threat detection

## 🗣️ **Natural Language Queries**

Ask Smith anything about your Mac:

### **Performance Questions**
- "Why is my Mac running slowly today?"
- "Which app is using the most CPU right now?"
- "Is my memory usage normal for what I'm doing?"
- "What's causing my fans to run so much?"

### **Storage & Files**
- "What's taking up the most space on my disk?"
- "Can I safely delete these large files?"
- "Where are my duplicate photos stored?"
- "What files haven't been accessed in months?"

### **Battery & Power**
- "Why is my battery draining so fast?"
- "Which apps are the biggest energy consumers?"
- "Is my charging pattern healthy?"
- "How much battery life should I expect?"

### **Applications & Processes**
- "Is this app safe to force quit?"
- "Why is this process using so much memory?"
- "Which background apps can I disable?"
- "Are all my apps up to date?"

### **System Health**
- "Is my Mac running optimally?"
- "Are there any security concerns I should know about?"
- "What maintenance should I perform?"
- "How does my Mac compare to when it was new?"

### **Optimization & Recommendations**
- "How can I speed up my Mac?"
- "What settings should I change for better performance?"
- "Can you optimize my startup items?"
- "What can I do to extend battery life?"

## 📊 **Comprehensive Monitoring**

Smith continuously monitors and understands:

### **Real-time Metrics**
- CPU usage per core and process
- Memory allocation and pressure
- Disk I/O and storage performance
- Network bandwidth and connectivity
- GPU utilization and performance
- Thermal sensors and fan speeds

### **Historical Analysis**
- Performance trends over time
- Resource usage patterns
- Application behavior analysis
- System health evolution
- Optimization opportunity tracking

### **Predictive Intelligence**
- Performance bottleneck prediction
- Maintenance need forecasting
- Battery health degradation
- Storage space planning
- Security vulnerability assessment

## 🎨 **Design Philosophy**

Smith follows Apple's design principles while prioritizing system intelligence:

- **Unobtrusive Monitoring** - Comprehensive awareness without impacting performance
- **Intuitive Interface** - Complex system data presented simply
- **Contextual Intelligence** - Understanding the relationships between system components
- **Accessible Colors** - Uses system colors (`Color.primary`, `Color.secondary`) for legible high-contrast UI
- **Proactive Assistance** - Anticipating needs before problems occur
- **Privacy Respect** - Complete system knowledge with zero data collection

## TODO 📝

### 🔥 **System Omniscience (High Priority)**
- [ ] **Complete CPU Intelligence** - Per-core monitoring, thermal throttling detection
- [ ] **Memory Mastery** - Allocation tracking, pressure analysis, swap monitoring
- [ ] **Storage Awareness** - Real-time I/O, health monitoring, space analysis
- [ ] **Network Intelligence** - Bandwidth monitoring, connection tracking, security analysis
- [ ] **Process Intelligence** - Complete process tree, resource attribution, behavior analysis
- [ ] **Hardware Monitoring** - All sensors, component health, performance metrics
- [ ] **Application Tracking** - Launch times, resource usage, efficiency scoring
- [ ] **File System Analysis** - Usage patterns, optimization opportunities, duplicate detection

### 🧠 **AI Knowledge Engine**
- [ ] **Natural Language Processing** - Understand complex system queries
- [ ] **Contextual Reasoning** - Connect system metrics to user experience
- [ ] **Predictive Analytics** - Forecast issues and optimization opportunities
- [ ] **Learning Algorithms** - Adapt to user patterns and preferences
- [ ] **Knowledge Graph** - Build relationships between system components
- [ ] **Explanation Engine** - Explain complex system states simply
- [ ] **Recommendation System** - Proactive optimization suggestions
- [ ] **Historical Intelligence** - Learn from past system behavior

### 📊 **Advanced Analytics**
- [ ] **Performance Benchmarking** - Compare against optimal baselines
- [ ] **Anomaly Detection** - Identify unusual system behavior
- [ ] **Trend Analysis** - Long-term performance and health trends
- [ ] **Correlation Analysis** - Find relationships between metrics
- [ ] **Efficiency Scoring** - Rate system and application efficiency
- [ ] **Health Scoring** - Overall system health assessment
- [ ] **Optimization Scoring** - Measure optimization effectiveness
- [ ] **Predictive Modeling** - Forecast future system needs

### 🔍 **Deep System Integration**
- [ ] **Kernel Extensions** - Access to lowest-level system information
- [ ] **System Call Monitoring** - Track all system interactions
- [ ] **Hardware Abstraction** - Direct hardware communication
- [ ] **Security Framework** - Monitor security events and threats
- [ ] **Network Stack** - Deep network protocol analysis
- [ ] **File System Events** - Track all file system changes
- [ ] **Process Monitoring** - Complete process lifecycle tracking
- [ ] **Memory Management** - Direct memory allocation tracking

### 🎯 **Knowledge Domains**
- [ ] **Thermal Intelligence** - Complete thermal management understanding
- [ ] **Power Management** - Advanced battery and power analysis
- [ ] **Graphics Intelligence** - GPU performance and efficiency monitoring
- [ ] **Audio System** - Audio hardware and software monitoring
- [ ] **Input/Output** - All I/O device monitoring and analysis
- [ ] **Virtualization** - VM and container resource tracking
- [ ] **Cloud Integration** - iCloud and cloud service monitoring
- [ ] **Developer Tools** - Xcode and development environment monitoring

### 🚀 **Platform Expansion**
- [ ] **iOS Integration** - Cross-device system awareness
- [ ] **watchOS Monitoring** - Apple Watch health and performance
- [ ] **tvOS Intelligence** - Apple TV system monitoring
- [ ] **HomePod Analysis** - Smart home device integration
- [ ] **Universal App** - Single intelligence across all platforms
- [ ] **Family Sharing** - Multi-Mac monitoring and management
- [ ] **Enterprise Edition** - Fleet monitoring and management
- [ ] **Developer API** - Third-party integration framework

## 🤝 Contributing

Help us build the most intelligent Mac assistant:
- **System Expertise** - macOS internals and performance optimization
- **AI/ML Knowledge** - Natural language processing and machine learning
- **User Experience** - Making complex data accessible and actionable
- **Testing** - Comprehensive system monitoring validation

## 📜 License

Smith is released under the MIT License. See LICENSE file for details.

## 🙏 Acknowledgments

- **Apple** - For Foundation Models, comprehensive APIs, and excellent development tools
- **macOS Community** - For deep system knowledge and optimization techniques
- **AI/ML Researchers** - For advances in on-device intelligence and natural language processing

---

**Built with ❤️ to know everything about your Mac**
