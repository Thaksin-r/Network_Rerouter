# 🌐 The Internet Goes Down – Network Rerouter

### Intelligent Network Resilience and Automatic Traffic Rerouting System

**Hackathon Project | Computer Networks | Network Security | Network Resilience**

## 📌 Overview

**The Internet Goes Down – Network Rerouter** is an intelligent network resilience system designed to maintain network connectivity when routers, communication links, or network paths fail.

In traditional networks, a failed connection can interrupt communication, cause packet loss, increase latency, and make critical services unavailable. This project simulates network failures and automatically identifies alternative paths to restore connectivity.

The system visualizes network topology, detects simulated link failures, calculates alternative routes, prioritizes critical traffic, and evaluates network performance before and after recovery.

The primary objective is to demonstrate how intelligent rerouting can improve network availability and reliability during unexpected network disruptions.

## 🎯 Problem Statement

Network infrastructure depends on interconnected routers, switches, communication links, and servers. A single point of failure can disrupt communication between multiple devices.

Traditional shortest-path routing may not always select the best alternative when remaining links are congested or have limited bandwidth.

This project addresses the problem by developing a network rerouting simulator that:

- Detects network link failures.
- Finds alternative paths dynamically.
- Considers link cost, latency, and congestion.
- Prioritizes critical network traffic.
- Measures network recovery and packet delivery performance.
- Visualizes network failures and recovery in real time.

## 💡 Proposed Solution

The proposed system represents a computer network as a graph consisting of nodes and edges.

- **Nodes:** Routers, switches, client devices, and servers.
- **Edges:** Network links connecting devices.
- **Link properties:** Latency, bandwidth, utilization, and operational status.
- **Traffic classes:** Critical traffic and normal traffic.

When a link fails, the system marks it as unavailable and recalculates a valid route. If multiple paths are available, the routing algorithm evaluates their costs and selects a suitable alternative.

If no valid path exists, the system reports the affected destination as unreachable rather than falsely claiming successful recovery.

## ✨ Key Features

### 1. Interactive Network Topology
- Visual representation of routers, servers, clients, and links.
- Display of network connectivity and link status.
- Support for predefined and customizable network topologies.

### 2. Network Failure Simulation
- Simulate router or link failures.
- Observe how failures affect connected devices.
- Identify isolated network segments and unreachable destinations.

### 3. Automatic Rerouting
- Detect unavailable links within the simulation.
- Recalculate routes when network topology changes.
- Avoid failed links during path selection.
- Restore connectivity when an alternative path exists.

### 4. Capacity-Aware Routing
- Consider link latency and congestion.
- Estimate available bandwidth.
- Assign configurable costs to network links.
- Compare shortest-path routing with capacity-aware routing.

### 5. Critical Traffic Prioritization
- Assign higher priority to designated critical traffic.
- Simulate preferential scheduling under congestion.
- Compare critical and normal traffic delivery rates.

### 6. Network Monitoring Dashboard
Display important performance indicators, including:
- Active and failed links.
- Selected network routes.
- Link utilization.
- Simulated packet delivery ratio.
- Packet drop rate.
- Route recovery time.
- Critical-service availability.

### 7. Incident Logging
- Record simulated network failures.
- Track route changes and recovery attempts.
- Generate performance summaries for each test scenario.

## 🏗️ System Architecture

The application follows a modular architecture.

```text
                 USER
                   |
                   v
       +------------------------+
       |  Interactive Frontend  |
       | Topology and Dashboard |
       +------------------------+
                   |
                   v
       +------------------------+
       |     Backend API        |
       |       FastAPI          |
       +------------------------+
                   |
          +--------+--------+
          |                 |
          v                 v
 +----------------+  +------------------+
 | Network Graph  |  | Failure Simulator|
 | Nodes and Links|  | Link/Router State|
 +----------------+  +------------------+
          |                 |
          +--------+--------+
                   |
                   v
       +------------------------+
       |   Routing Engine       |
       | Dijkstra / Cost Model  |
       +------------------------+
                   |
                   v
       +------------------------+
       | Traffic and Metrics    |
       | Recovery / Packet Stats|
       +------------------------+
                   |
                   v
       +------------------------+
       | Dashboard and Reports  |
       +------------------------+
```

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| Frontend | React.js, HTML, CSS, JavaScript |
| Backend | Python, FastAPI |
| Graph representation | NetworkX |
| Routing algorithm | Dijkstra's algorithm |
| Alternative routing strategy | Capacity-aware path cost |
| Visualization | React Flow or an equivalent graph visualization library |
| Charts | Recharts |
| Communication | REST API |
| Data storage | In-memory data structures; optional SQLite for persistent logs |
| Development tools | VS Code, Git, GitHub |

*The stack describes the proposed implementation. Individual components should be updated to match the technologies actually implemented.*

## 🧠 Algorithms Used

### 1. Dijkstra's Shortest-Path Algorithm

Finds the minimum-cost path between a source and destination in a graph with non-negative edge weights.

When a link fails, the system excludes that link and recalculates the route.

### 2. Capacity-Aware Routing

Uses a configurable cost function to account for latency and congestion.

For example:

`Link Cost = α × Latency + β × Congestion + γ × Failure Penalty`

Where:
- `α` controls the importance of latency.
- `β` controls the importance of congestion.
- `γ` controls the failure-risk penalty.

Unavailable links must be excluded from candidate routes. The cost function can be extended to account for bandwidth requirements.

### 3. Priority-Based Traffic Scheduling

Classifies traffic into categories, such as:
- Critical: authentication and essential service traffic.
- Normal: regular application traffic.
- Background: bulk transfers and non-urgent downloads.

A priority scheduler serves critical traffic preferentially when capacity is constrained. Priority scheduling does not itself guarantee connectivity if every available route has failed.

## ⚙️ How the System Works

1. **Initialize:** Create the network topology and configure link properties.
2. **Generate traffic:** Simulate traffic between selected source and destination nodes.
3. **Monitor:** Track link status and network performance.
4. **Inject failure:** Mark a router or communication link as unavailable.
5. **Detect:** Identify affected routes and destinations.
6. **Recalculate:** Find an alternative path using the routing engine.
7. **Reroute:** Update the selected path if a valid alternative exists.
8. **Evaluate:** Calculate recovery time, packet delivery ratio, packet drops, and critical traffic performance.
9. **Report:** Display the new topology and performance comparison.

## 📊 Performance Metrics

| Metric | Description |
|---|---|
| Recovery Time | Time required to calculate and apply an alternative route in the simulator |
| Packet Delivery Ratio | Successfully delivered simulated packets divided by total generated packets |
| Packet Drop Rate | Undelivered simulated packets divided by total generated packets |
| Link Utilization | Used link capacity divided by total link capacity |
| Route Cost | Total cost of the selected route |
| Critical Traffic Delivery | Percentage of generated critical packets delivered |
| Network Availability | Percentage of the simulation period during which a specified service is reachable |

Performance results must be obtained from actual test runs. No experimental results are assumed in this README.

## 🧪 Testing Scenarios

The project should be tested using the following scenarios:

1. **Normal Operation:** All links are operational.
2. **Single Link Failure:** A primary communication link fails.
3. **Router Failure:** A router becomes unavailable.
4. **Multiple Link Failures:** Several links fail simultaneously.
5. **Congestion:** Traffic load increases on selected links.
6. **Critical Traffic Under Congestion:** Critical and normal traffic compete for limited capacity.
7. **Network Partition:** No valid route exists between selected nodes.
8. **Recovery:** A failed link becomes operational again.

For fair comparisons, test different routing algorithms using the same network topology, traffic load, and failure conditions.

## 🚀 Installation and Setup

### Prerequisites

Install the following:
- Python 3.11 or a compatible version.
- Node.js and npm.
- Git (optional).
- Visual Studio Code (recommended).

### 1. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd network-rerouter
```

Replace `<YOUR_REPOSITORY_URL>` with your actual repository URL.

### 2. Set Up the Backend

```bash
cd backend
python -m venv venv
```

Activate the environment on Windows:

```powershell
venv\Scripts\Activate.ps1
```

Install the Python dependencies:

```bash
pip install fastapi uvicorn networkx
```

Start the backend after creating the application entry point:

```bash
uvicorn main:app --reload
```

The API documentation should be available at:

`http://127.0.0.1:8000/docs`

### 3. Set Up the Frontend

Open a separate terminal:

```bash
cd frontend
npm install
npm run dev
```

Open the local development URL printed by the frontend development server.

**Note:** These commands assume the repository contains `backend/main.py` and a frontend project with a valid `package.json`. The commands install core backend dependencies; additional visualization or chart packages may be required by your implementation.

## 📁 Suggested Project Structure

```text
network-rerouter/
├── backend/
│   ├── main.py
│   ├── network_topology.py
│   ├── failure_simulator.py
│   ├── routing_engine.py
│   ├── traffic_manager.py
│   ├── metrics.py
│   ├── requirements.txt
│   └── tests/
│       └── test_routing.py
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── App.jsx
│   ├── package.json
│   └── index.html
├── docs/
│   └── architecture.md
├── screenshots/
├── README.md
└── .gitignore
```

## 🔐 Security and Limitations

- The initial implementation is a controlled simulation, not a production routing protocol.
- Simulated recovery time does not represent real-world convergence time.
- Packet delivery results depend on the traffic and failure models used.
- Critical traffic prioritization requires an explicit scheduling or queueing model.
- Real network integration would require appropriate privileges, routing configuration, monitoring, and safety testing.
- The simulator must not claim that an unreachable destination has been successfully recovered.

## 🔮 Future Enhancements

- Machine-learning-based congestion prediction.
- Predictive identification of potentially failing links.
- Reinforcement-learning-based routing experiments.
- Real-time telemetry integration.
- Multi-path routing and load balancing.
- Container-based network experiments using Mininet.
- Integration with Linux routing tools in an isolated test environment.
- Automated incident reports and downloadable performance summaries.

## 🎯 Expected Outcome

The expected outcome is an interactive simulator that demonstrates how network connectivity can be maintained during failures by detecting unavailable links, finding alternative routes, and prioritizing critical traffic.

The system will help users understand network resilience, graph-based routing, congestion management, failure recovery, and the importance of redundant network paths.

## 👥 Team Contributions

Suggested division of work for a four-member team:

| Member | Responsibility |
|---|---|
| Member 1 | Frontend and network visualization |
| Member 2 | Routing algorithms and graph modeling |
| Member 3 | Failure simulation, traffic management, and metrics |
| Member 4 | Backend integration, testing, and documentation |

For smaller teams, combine related responsibilities.

## 🏁 Conclusion

**The Internet Goes Down – Network Rerouter** demonstrates an approach to improving network resilience through dynamic path selection, network failure simulation, and critical traffic prioritization.

By combining graph algorithms, congestion-aware routing, and performance monitoring, the project provides a practical environment for studying how computer networks can respond to disruptions and preserve essential connectivity.

---

**Project Category:** Computer Networks, Network Security, Network Resilience

**Project Type:** Interactive Network Simulation and Routing System

**Developed for:** Hackathon

**License:** To be selected by the project team.
