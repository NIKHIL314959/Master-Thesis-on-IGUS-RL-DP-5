TYPE
	McTPTypEnum :
		( (*Type selector setting*)
		mcTPT_LIN := 0 (*Linear - Linear tracking path*)
		);
	McTPLinMotSrcEnum :
		( (*Motion source selector setting*)
		mcTPTLMS_POS_PROC_VAR := 0, (*Position process variable - Position provided by process variable*)
		mcTPTLMS_AX := 1 (*Axis - Axis*)
		);
	McTPLinMotSrcPosPVMoveLimEnum :
		( (*Movement limits selector setting*)
		mcTPTLMSPPVML_INT := 0 (*Internal - Internal definition of limits*)
		);
	McTPLMSPPVMLIVelEnum :
		( (*Velocity selector setting*)
		mcTPTLMSPPVMLIV_BASIC := 0 (*Basic -*)
		);
	McTPLMSPPVMLIVelBasicType : STRUCT (*Type mcTPTLMSPPVMLIV_BASIC settings*)
		Velocity : REAL; (*Velocity limit in any movement direction [Measurement units/s]*)
	END_STRUCT;
	McTPLMSPPVMLIVelType : STRUCT (*Limits for velocity*)
		Type : McTPLMSPPVMLIVelEnum; (*Velocity selector setting*)
		Basic : McTPLMSPPVMLIVelBasicType; (*Type mcTPTLMSPPVMLIV_BASIC settings*)
	END_STRUCT;
	McTPLMSPPVMLIAccEnum :
		( (*Acceleration selector setting*)
		mcTPTLMSPPVMLIA_BASIC := 0 (*Basic -*)
		);
	McTPLMSPPVMLIAccBasicType : STRUCT (*Type mcTPTLMSPPVMLIA_BASIC settings*)
		Acceleration : REAL; (*Acceleration limit in any movement direction [Measurement units/s²]*)
	END_STRUCT;
	McTPLMSPPVMLIAccType : STRUCT (*Limits for acceleration*)
		Type : McTPLMSPPVMLIAccEnum; (*Acceleration selector setting*)
		Basic : McTPLMSPPVMLIAccBasicType; (*Type mcTPTLMSPPVMLIA_BASIC settings*)
	END_STRUCT;
	McTPLMSPPVMLIType : STRUCT (*Type mcTPTLMSPPVML_INT settings*)
		Velocity : McTPLMSPPVMLIVelType; (*Limits for velocity*)
		Acceleration : McTPLMSPPVMLIAccType; (*Limits for acceleration*)
	END_STRUCT;
	McTPLinMotSrcPosPVMoveLimType : STRUCT (*Velocity, acceleration and deceleration limits to be considered*)
		Type : McTPLinMotSrcPosPVMoveLimEnum; (*Movement limits selector setting*)
		Internal : McTPLMSPPVMLIType; (*Type mcTPTLMSPPVML_INT settings*)
	END_STRUCT;
	McTPLinMotSrcPosPVPrepEnum :
		( (*Signal preparation selector setting*)
		mcTPTLMSPPVP_NO_PREP := 0, (*No preparation - Suitable for high quality input signals*)
		mcTPTLMSPPVP_LIN_REG := 1 (*Linear regression - Suitable for low quality input signals*)
		);
	McTPLinMotSrcPosPVPrepLinRegType : STRUCT (*Type mcTPTLMSPPVP_LIN_REG settings*)
		ConsideredSamples : DINT; (*Number of samples used for calculating the velocity [Samples]*)
		PositionDisturbance : LREAL; (*Considered magnitude of position disturbance effects [Measurement units]*)
	END_STRUCT;
	McTPLinMotSrcPosPVPrepType : STRUCT (*Preparation of the input signal from Motion source*)
		Type : McTPLinMotSrcPosPVPrepEnum; (*Signal preparation selector setting*)
		LinearRegression : McTPLinMotSrcPosPVPrepLinRegType; (*Type mcTPTLMSPPVP_LIN_REG settings*)
	END_STRUCT;
	McTPLinMotSrcPosPVType : STRUCT (*Type mcTPTLMS_POS_PROC_VAR settings*)
		ProcessVariableName : STRING[250]; (*Process variable name to get current position*)
		NegativeOverflow : LREAL; (*Positionoverflow in negative direction*)
		PositiveOverflow : LREAL; (*Positionoverflow in positive direction*)
		DelayTime : LREAL; (*Delay time of tracking path position signal for error compensation (filtering, delay of signals, ...) [s]*)
		MovementLimits : McTPLinMotSrcPosPVMoveLimType; (*Velocity, acceleration and deceleration limits to be considered*)
		Preparation : McTPLinMotSrcPosPVPrepType; (*Preparation of the input signal from Motion source*)
	END_STRUCT;
	McTPLinMotSrcAxAxUseEnum :
		( (*Axis usage selector setting*)
		mcTPTLMSAAU_ACT := 0, (*Active - The configured axis actively moves the transport system*)
		mcTPTLMSAAU_PASS := 1 (*Passive - The configured axis is used to filter the position input signal only*)
		);
	McTPLinCCEnum :
		( (*Command consideration selector setting*)
		mcTPLINCC_NOT_USE := 0, (*Not used - The internal motion planning does not consider motion commands sent to the configured axis. Automatic delay time compensation is available.*)
		mcTPLINCC_SPT_BASIC_CMD := 1 (*Support basic commands - The internal motion planning considers basic motion commands sent to the configured axis. Automatic delay time compensation is not available.*)
		);
	McTPLinCCType : STRUCT (*Defines how motion commands sent to the configured axis are used*)
		Type : McTPLinCCEnum; (*Command consideration selector setting*)
	END_STRUCT;
	McTPLinMotSrcAxAxUseActType : STRUCT (*Type mcTPTLMSAAU_ACT settings*)
		CommandConsideration : McTPLinCCType; (*Defines how motion commands sent to the configured axis are used*)
	END_STRUCT;
	McTPLinMotSrcAxAxUseType : STRUCT (*Defines how the axis is used*)
		Type : McTPLinMotSrcAxAxUseEnum; (*Axis usage selector setting*)
		Active : McTPLinMotSrcAxAxUseActType; (*Type mcTPTLMSAAU_ACT settings*)
	END_STRUCT;
	McTPLinMotSrcAxMoveLimEnum :
		( (*Movement limits selector setting*)
		mcTPTLMSAML_USE_AX_LIM := 0, (*Use axis limits - Internal definition of limits*)
		mcTPTLMSAML_INT := 1 (*Internal - Internal definition of limits*)
		);
	McTPLMSAMLIVelEnum :
		( (*Velocity selector setting*)
		mcTPTLMSAMLIV_BASIC := 0 (*Basic -*)
		);
	McTPLMSAMLIVelBasicType : STRUCT (*Type mcTPTLMSAMLIV_BASIC settings*)
		Velocity : REAL; (*Velocity limit in any movement direction [Measurement units/s]*)
	END_STRUCT;
	McTPLMSAMLIVelType : STRUCT (*Limits for velocity*)
		Type : McTPLMSAMLIVelEnum; (*Velocity selector setting*)
		Basic : McTPLMSAMLIVelBasicType; (*Type mcTPTLMSAMLIV_BASIC settings*)
	END_STRUCT;
	McTPLMSAMLIAccEnum :
		( (*Acceleration selector setting*)
		mcTPTLMSAMLIA_BASIC := 0 (*Basic -*)
		);
	McTPLMSAMLIAccBasicType : STRUCT (*Type mcTPTLMSAMLIA_BASIC settings*)
		Acceleration : REAL; (*Acceleration limit in any movement direction [Measurement units/s²]*)
	END_STRUCT;
	McTPLMSAMLIAccType : STRUCT (*Limits for acceleration*)
		Type : McTPLMSAMLIAccEnum; (*Acceleration selector setting*)
		Basic : McTPLMSAMLIAccBasicType; (*Type mcTPTLMSAMLIA_BASIC settings*)
	END_STRUCT;
	McTPLMSAMLIType : STRUCT (*Type mcTPTLMSAML_INT settings*)
		Velocity : McTPLMSAMLIVelType; (*Limits for velocity*)
		Acceleration : McTPLMSAMLIAccType; (*Limits for acceleration*)
	END_STRUCT;
	McTPLinMotSrcAxMoveLimType : STRUCT (*Velocity, acceleration and deceleration limits to be considered*)
		Type : McTPLinMotSrcAxMoveLimEnum; (*Movement limits selector setting*)
		Internal : McTPLMSAMLIType; (*Type mcTPTLMSAML_INT settings*)
	END_STRUCT;
	McTPLinMotSrcAxPrepEnum :
		( (*Signal preparation selector setting*)
		mcTPTLMSAP_NO_PREP := 0, (*No preparation - Suitable for high quality input signals*)
		mcTPTLMSAP_LIN_REG := 1 (*Linear regression - Suitable for low quality input signals*)
		);
	McTPLinMotSrcAxPrepLinRegType : STRUCT (*Type mcTPTLMSAP_LIN_REG settings*)
		ConsideredSamples : DINT; (*Number of samples used for calculating the velocity [Samples]*)
		PositionDisturbance : LREAL; (*Considered magnitude of position disturbance effects [Measurement units]*)
	END_STRUCT;
	McTPLinMotSrcAxPrepType : STRUCT (*Preparation of the input signal from Motion source*)
		Type : McTPLinMotSrcAxPrepEnum; (*Signal preparation selector setting*)
		LinearRegression : McTPLinMotSrcAxPrepLinRegType; (*Type mcTPTLMSAP_LIN_REG settings*)
	END_STRUCT;
	McTPLinMotSrcAxType : STRUCT (*Type mcTPTLMS_AX settings*)
		AxisReference : McCfgReferenceType; (*Name of the axis reference*)
		AxisUsage : McTPLinMotSrcAxAxUseType; (*Defines how the axis is used*)
		DelayTime : LREAL; (*Additional delay time of tracking path position signal for error compensation [s]*)
		MovementLimits : McTPLinMotSrcAxMoveLimType; (*Velocity, acceleration and deceleration limits to be considered*)
		Preparation : McTPLinMotSrcAxPrepType; (*Preparation of the input signal from Motion source*)
	END_STRUCT;
	McTPLinMotSrcType : STRUCT (*Source describing the tracking path movement*)
		Type : McTPLinMotSrcEnum; (*Motion source selector setting*)
		PositionProcessVariable : McTPLinMotSrcPosPVType; (*Type mcTPTLMS_POS_PROC_VAR settings*)
		Axis : McTPLinMotSrcAxType; (*Type mcTPTLMS_AX settings*)
	END_STRUCT;
	McTPLinType : STRUCT (*Type mcTPT_LIN settings*)
		MaxTrackingFrames : UINT; (*Maximum number of tracking frames*)
		MaxPositionError : LREAL; (*Maximal deviation between tracking frames and motion source position when considering tracking path movement limits [Measurement units]*)
		MotionSource : McTPLinMotSrcType; (*Source describing the tracking path movement*)
	END_STRUCT;
	McTPTypType : STRUCT (*Geometry of tracking path*)
		Type : McTPTypEnum; (*Type selector setting*)
		Linear : McTPLinType; (*Type mcTPT_LIN settings*)
	END_STRUCT;
	McCfgTrkPathType : STRUCT (*Main data type corresponding to McCfgTypeEnum mcCFG_TRK_PATH*)
		Type : McTPTypType; (*Geometry of tracking path*)
	END_STRUCT;
	McTPSVEnum :
		( (*Scene Viewer Object selector setting*)
		mcTPSSVO_USE := 0, (*Used - TrackingPath object is used*)
		mcTPSSVO_NOT_USE := 1 (*Not used -*)
		);
	McTPSVUseNameEnum :
		( (*Name selector setting*)
		mcTPSSVOUN_VIS := 0, (*Visible - Name is displayed*)
		mcTPSSVOUN_INVIS := 1 (*Invisible - Name is hidden*)
		);
	McTPSVUseNameType : STRUCT (*Defines if TrackingPath name is visible*)
		Type : McTPSVUseNameEnum; (*Name selector setting*)
	END_STRUCT;
	McTPSVUseFrmEnum :
		( (*Frame selector setting*)
		mcTPSSVOUF_VIS := 0, (*Visible - Frame is displayed*)
		mcTPSSVOUF_INVIS := 1 (*Invisible - Frame is hidden*)
		);
	McTPSVUseFrmType : STRUCT (*Defines if TrackingPath frame is be visible*)
		Type : McTPSVUseFrmEnum; (*Frame selector setting*)
	END_STRUCT;
	McTPSVUseVREnum :
		( (*Visual representation selector setting*)
		mcTPSSVOUVR_NOT_USE := 0, (*Not used - No additional representation*)
		mcTPSSVOUVR_CUBE := 1, (*Cuboid - Shows a cuboid under the TrackingPath*)
		mcTPSSVOUVR_CNVR_BELT := 2 (*Conveyor belt - Shows a conveyor belt under the TrackingPath*)
		);
	McTPSVUseVRCubeDimType : STRUCT (*Dimensions of the object*)
		Length : LREAL; (*Length of the cuboid [Measurement units]*)
		Width : LREAL; (*Width of the cuboid [Measurement units]*)
		Height : LREAL; (*Height of the cuboid [Measurement units]*)
	END_STRUCT;
	McTPSVUseVRCubeType : STRUCT (*Type mcTPSSVOUVR_CUBE settings*)
		Dimensions : McTPSVUseVRCubeDimType; (*Dimensions of the object*)
		Translation : McCfgTransXYZType; (*Translation parameters*)
		Orientation : McCfgOrientType; (*Orientation parameters*)
		Material : McScnSurfaceEnum; (*Material*)
	END_STRUCT;
	McTPSVUseVRCnvrBeltDimType : STRUCT (*Dimensions of the object*)
		Length : LREAL; (*Length of the conveyor belt [Measurement units]*)
		Width : LREAL; (*Width of the conveyor belt [Measurement units]*)
		Height : LREAL; (*Height of the conveyor belt [Measurement units]*)
	END_STRUCT;
	McTPSVUseVRCnvrBeltType : STRUCT (*Type mcTPSSVOUVR_CNVR_BELT settings*)
		Dimensions : McTPSVUseVRCnvrBeltDimType; (*Dimensions of the object*)
		Translation : McCfgTransXYZType; (*Translation parameters*)
		Orientation : McCfgOrientType; (*Orientation parameters*)
		Material : McScnSurfaceEnum; (*Material*)
	END_STRUCT;
	McTPSVUseVRType : STRUCT (*Defines a (physical) object representing the TrackingPath*)
		Type : McTPSVUseVREnum; (*Visual representation selector setting*)
		Cuboid : McTPSVUseVRCubeType; (*Type mcTPSSVOUVR_CUBE settings*)
		ConveyorBelt : McTPSVUseVRCnvrBeltType; (*Type mcTPSSVOUVR_CNVR_BELT settings*)
	END_STRUCT;
	McTPSVUseContEnum :
		( (*Content selector setting*)
		mcTPSSVOUC_NOT_USE := 0, (*Not used - TrackingFrames visualization is deactivated*)
		mcTPSSVOUC_VIS := 1 (*Visible - TrackingFrames visualization is activated*)
		);
	McTPSVUseContType : STRUCT (*Defines if the TrackingFrames in the TrackingPath are visualized*)
		Type : McTPSVUseContEnum; (*Content selector setting*)
	END_STRUCT;
	McTPSVUseType : STRUCT (*Type mcTPSSVO_USE settings*)
		Name : McTPSVUseNameType; (*Defines if TrackingPath name is visible*)
		Frame : McTPSVUseFrmType; (*Defines if TrackingPath frame is be visible*)
		VisualRepresentation : McTPSVUseVRType; (*Defines a (physical) object representing the TrackingPath*)
		Content : McTPSVUseContType; (*Defines if the TrackingFrames in the TrackingPath are visualized*)
	END_STRUCT;
	McTPSVType : STRUCT (*Defines if the TrackingPath is contained in the automatically generated scene*)
		Type : McTPSVEnum; (*Scene Viewer Object selector setting*)
		Used : McTPSVUseType; (*Type mcTPSSVO_USE settings*)
	END_STRUCT;
	McCfgTrkPathScnType : STRUCT (*Main data type corresponding to McCfgTypeEnum mcCFG_TRK_PATH_SCN*)
		SceneViewerObject : McTPSVType; (*Defines if the TrackingPath is contained in the automatically generated scene*)
	END_STRUCT;
END_TYPE