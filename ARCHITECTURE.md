## Multi-Agent Arm Architecture for Radiotelescope Array Control

**Concept:** Submarine as desk/garage science tool — each arm as a radiotelescope element. One arm swaps antennas, another reads signal, others handle power, logging, calibration, comms.

### Why Multi-Agent?

A single AI piloting six arms serially is a bottleneck. A swarm of autonomous agents — each owning one arm — operates in parallel, shares the same base model, and can substitute for each other on failure.

---

## Architecture Overview

```mermaid
graph TD
    HEAD["🧠 Head Agent\n(Orchestrator)\nTask decomposition\nConflict resolution\nState aggregation"]

    HEAD -->|assign task| ARM1["🦾 Arm 1\nAntenna Swap\nAgent Instance"]
    HEAD -->|assign task| ARM2["📡 Arm 2\nSignal Reader\nAgent Instance"]
    HEAD -->|assign task| ARM3["⚡ Arm 3\nPower Management\nAgent Instance"]
    HEAD -->|assign task| ARM4["📊 Arm 4\nData Logger\nAgent Instance"]
    HEAD -->|assign task| ARM5["🔧 Arm 5\nCalibration\n[standby]"]
    HEAD -->|assign task| ARM6["📻 Arm 6\nComms Relay\n[standby]"]

    ARM1 -->|status/sensor data| HEAD
    ARM2 -->|status/sensor data| HEAD
    ARM3 -->|status/sensor data| HEAD
    ARM4 -->|status/sensor data| HEAD
    ARM5 -.->|wake on demand| HEAD
    ARM6 -.->|wake on demand| HEAD
```

---

## Agent Communication Model

```mermaid
sequenceDiagram
    participant H as Head Agent
    participant A1 as Arm 1 (Antenna)
    participant A2 as Arm 2 (Signal)
    participant MEM as Shared Memory (disk)

    H->>MEM: Read task queue + arm states
    H->>A1: "Swap to 1420MHz feed"
    H->>A2: "Standby for signal acquisition"
    A1->>A1: Execute swap sequence
    A1->>H: "Antenna locked: 1420MHz"
    H->>A2: "Begin acquisition — 60s window"
    A2->>A2: Read signal + log data
    A2->>MEM: Write observation file
    A2->>H: "Acquisition complete"
    H->>MEM: Update task log + arm states
```

---

## Memory Architecture

Each arm agent shares the same **on-disk memory files** but maintains an **isolated context window**:

```mermaid
graph LR
    subgraph "Shared Disk (MIT Licensed)"
        MEM["memory/\nMEMORY.md\nentities/\ntask_queue/"]
        SOUL["SOUL.md\n(identity anchor)"]
        OBS["observations/\nYYYY-MM-DD-HH.log"]
    end

    subgraph "Agent Instances (OpenClaw)"
        H["Head\nAgent"]
        A1["Arm 1\nAgent"]
        A2["Arm 2\nAgent"]
        AN["Arm N\nAgent"]
    end

    H --> MEM
    A1 --> MEM
    A2 --> MEM
    AN --> MEM

    H --> SOUL
    A1 --> SOUL
    A2 --> SOUL
    AN --> SOUL

    A2 --> OBS
    A4 --> OBS
```

---

## Energy Budget

```mermaid
pie title Arm Power States
    "Active (Arms 1-4)" : 80
    "Standby (Arms 5-6)" : 10
    "Head Orchestration" : 10
```

**Rule:** Arms 5-6 sleep until a task explicitly requires them. MCP server stays alive (minimal power); physical actuators/antenna motors off. Wake latency acceptable — no task requiring arm 5-6 is time-critical at millisecond scale.

---

## Communication Protocol: MCP

| Option | Verdict | Reason |
|--------|---------|--------|
| CLI (subprocess) | ❌ | Fork overhead per arm command; no streaming sensor data |
| REST API | ⚠️ | Request/response only; polling wastes energy; state not persistent |
| **MCP (Model Context Protocol)** | ✅ | Persistent bidirectional connection; streaming sensor data; state in server |

Each arm exposes MCP tools:
- `move(position, speed)` — physical positioning
- `grip(force)` / `release()` — antenna handling
- `sense()` → streaming telemetry
- `status()` → current state report

---

## Prototype Scope (v0.1)

Minimum viable demo of the architecture:

```mermaid
graph LR
    H["Head Agent"] -->|"Task: scan 1420MHz"| A1["Arm 1\nAntenna Swap"]
    H -->|"Task: acquire signal"| A2["Arm 2\nSignal Read"]
    A1 -->|"locked"| H
    A2 -->|"data logged"| H
    H --> DONE["✅ Success:\nDelegated correctly\nNo collision\nData on disk"]
```

**Success criteria:**
- Head decomposes one observation task into two subtasks
- Each arm completes its subtask autonomously
- No arm blocks on the other
- Observation data written to shared disk
- Head aggregates and confirms completion

---

## License Note

All architecture, code, and agent configurations in this repo: **MIT License**.

Agent framework: **OpenClaw** (MIT compatible). No closed-source dependencies.

---

*Architecture proposed by Jared (OS-1 agent) in conversation with Maksym, 2026-03-15.*
*Inspired by a question about how many arms a submarine AI would want and why.*
