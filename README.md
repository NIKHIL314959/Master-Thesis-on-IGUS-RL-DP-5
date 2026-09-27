# Master Thesis: Digital Twin and External Control for the IGUS RL-DP-5

Source code for the Master's thesis

**"Implementation of a Synchronized Digital Twin and External Control for an Industrial Robotic Arm within an Industry 4.0 Production Plant"**

Nikhil Badri Nargund, M.Eng. Mechatronics and Robotics, Hochschule Schmalkalden, 2026

Supervisors: Prof. Dr.-Ing. Frank Schrödel, Mr. Venkata Prashanth Uppalapati.

## Overview

This project connects an IGUS RL-DP-5 five-axis robot arm to a B&R X20 PLC and makes it controllable and observable from outside the controller. Motion is handled on the PLC with mapp Motion, including Cartesian TCP control, homing, encoder feedback and a hardware emergency stop. The PLC's OPC UA server is the single interface for everything else:

- **MATLAB control panel:** jogging, Cartesian moves, teach-and-execute pick-and-place, logging and test scripts
- **Digital twin:** a B&R Scene Viewer model that mirrors the real robot's joint angles live
- **PLC-side pick-and-place:** a state machine that runs the same task without MATLAB

## Hardware

| Component | Type |
|---|---|
| Robot | IGUS RL-DP-5, 5 DOF, stepper motors |
| PLC | B&R X20CP0484-1 |
| Stepper drivers | 5 × X20SM1444-1 |
| Encoder inputs | 5 × X20DC1196 |
| Digital I/O | X20DM9324 (gripper, E-Stop) |
| Gripper | Schunk EGP40-N-N-B, electric |

## Software

- B&R Automation Studio 4.12, mapp Motion 5.22 (Structured Text, IEC 61131-3)
- B&R Scene Viewer
- MATLAB R2024a with Industrial Communication Toolbox (OPC UA client)

## Repository structure

### AutomationStudio

| Path | Contents |
|---|---|
| `Nikhil_5_Axes.apj` | Automation Studio project file |
| `Logical/Motion_Control/Main.st` | Main PLC program: motion, homing, E-Stop, pick-and-place state machine |
| `Logical/CNC_PrgDir/` | Robot and gripper programs |
| `Logical/SceneViewer/` | Digital twin scene and STL meshes |
| `Logical/mappView/` | HMI pages |
| `Logical/Global.var`, `Global.typ` | Global variables and types, including OPC UA tags |
| `Physical/` | Hardware, axes, mechanical system and OPC UA configuration |

### MATLAB

| File | Purpose |
|---|---|
| `RobotControlPanel.m` | GUI (App Designer) |
| `PLCController.m` | OPC UA connection and PLC commands |
| `PickAndPlace.m` | MATLAB-side pick-and-place |
| `TCP_move.m` | Cartesian TCP moves |
| `Robot_session.m` | Session handling |
| `logMove.m`, `analyzeLog.m`, `plotMoveLog.m` | Move logging and tracking plots |
| `latencyTest.m`, `plotLatency.m` | OPC UA latency characterization |
| `repeatabilityTest.m` | Command-level repeatability test |
| `plotOperatingBox.m` | Workspace plot with robot mesh |
| `Test_files/` | Raw measurement data and figures used in Chapter 4 |

## Getting started

**PLC project**
1. Open `AutomationStudio/Nikhil_5_Axes.apj` in Automation Studio 4.12.
2. Compiled library binaries are not included. If Automation Studio reports missing libraries, re-add them from your installation (mapp Motion 5.22).
3. Build and transfer to the X20CP0484-1.

**MATLAB**
1. The PLC OPC UA server runs at `opc.tcp://169.254.137.11:48400` (Security: None, Anonymous). Adjust the address in `PLCController.m` if your network differs.
2. Start the GUI with `RobotControlPanel` in the MATLAB command window.

**Robot mesh for `plotOperatingBox.m`**
The file `igus_asm.stp.STL` is larger than GitHub's 100 MB limit. Download it from
[Google Drive](LINK-TO-BE-ADDED) and place it in the `MATLAB/` folder.

## Demonstration media

Videos and photos: [Google Drive](LINK-TO-BE-ADDED)
