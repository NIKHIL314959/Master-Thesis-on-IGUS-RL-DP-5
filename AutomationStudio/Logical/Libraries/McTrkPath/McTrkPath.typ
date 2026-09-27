
TYPE
	McTrkPathPLCopenStateEnum :
		(
		mcTRKPATH_STARTUP,
		mcTRKPATH_READY,
		mcTRKPATH_ERRORSTOP,
		mcTRKPATH_INVALID_CONFIGURATION
		);
	McTrkFrmGetModEnum :
		(
		mcTRKPATH_GET_MOD_ALL_FRAMES := 0, (*Get all tracking frames*)
		mcTRKPATH_GET_MOD_CERTAIN_FRAME := 1 (*Get tracking frame with a certain ID*)
		);
	McTrkFrmInfoModEnum :
		(
		mcTRKPATH_INFO_MOD_ALL := 0, (*Everything*)
		mcTRKPATH_INFO_MOD_ID_ONLY := 1, (*Only tracking frame ID and attribute*)
		mcTRKPATH_INFO_MOD_POSE := 2, (*Tracking frame orientation and translation (+ tracking frame ID and attribute) *)
		mcTRKPATH_INFO_MOD_DIST := 3, (*Distance to tracking path (+ tracking frame ID and attribute) *)
		mcTRKPATH_INFO_MOD_POSE_DIST := 4 (*Tracking frame orientation, translation and distance to tracking path (+tracking frame ID and attribute) *)
		);
	McTrkFrmDeleteModEnum :
		(
		mcTRKFRM_DELETE_MOD_FRAME := 0, (*Delete tracking frame with given tracking frame ID*)
		mcTRKFRM_DELETE_MOD_ALL := 1 (*Delete all tracking frames existing on the tracking path*)
		);
	McTrkPathBasicCmdConsiderEnum :
		(
		mcTRKPATH_AXCMDC_NOT_SUPPORTED := 0, (*movement type not supported*)
		mcTRKPATH_AXCMDC_TARGET_POS := 1, (*movement type position consideration*)
		mcTRKPATH_AXCMDC_TARGET_VEL :=2   (*movement type velocity consideration*)
		);
	McTrkFrmInfoType : 	STRUCT
		TrackingFrameID : McTrkFrmIdentType; (*Tracking frame ID*)
		CurrentPosition : McPosType; (*Current position of the tracking frame*)
		CurrentOrientation : McOrientType; (*Current orientation of the tracking frame*)
		Distance : LREAL; (*Distance from tracking path coordinate system to the tracking frame along the x-axis*)
		Attribute : UDINT; (*Attribute which was given to the tracking frame*)
	END_STRUCT;
	McTrkFramesCreateParType : 	STRUCT
		DataAddress : {REDUND_UNREPLICABLE} UDINT; (*Address of McTrkFrmCreateParType array. *)
		NumberOfFrames : UINT; (*Defines the number of tracking frames to be created. The value must not exceed the number of array elements referenced at DataAddress input*)
	END_STRUCT;
	McTrkFrmCreateParType : 	STRUCT
		LatchedPath : McTrkFrmLatPathType; (*Parameter for latched path position*)
		Translation : McPosType; (*Translation of current tracking frame to tracking path coordinate system*)
		Orientation : McOrientType; (*Orientation of current tracking frame relative to tracking path coordinate system*)
		Attribute : UDINT; (*Optional attribute which can be added to the tracking frame. E.g. productID, quality or color *)
	END_STRUCT;
	McTrkFrmLatPathType : 	STRUCT
		Position : LREAL; (*Latched tracking path position*)
	END_STRUCT;
	McTrkPathGetFrmParType : 	STRUCT
		GetMode : McTrkFrmGetModEnum; (*Mode to define which tracking frames are to be read*)
		InfoMode : McTrkFrmInfoModEnum; (*Mode to define which tracking frame information is needed*)
		TrackingFrameID : McTrkFrmIdentType; (*Tracking frame ID (GetMode = mcTRKPATH_GET_MOD_CERTAIN_FRAME)*)
		CoordSystem : UDINT; (*Coordinate system in which translation and orientation is given. mcMCS defines the tracking path coordinate system*)
		DataAddress : {REDUND_UNREPLICABLE} UDINT; (*Address of McTrkFrmInfoType array. *)
		NumberOfFrames : UINT; (*Defines the number of array elements of McTrkFrmInfoType array referenced at DataAddress input*)
	END_STRUCT;
	McTrkFrmIdentType : UDINT; (*Tracking frame identification type*)
	McTrkPathEstimatedMotionState : 	STRUCT
		Position : LREAL;	(*Estimated position*)
		Velocity : REAL;	(*Estimated velocity*)
	END_STRUCT;
	McTrkPathInfoType : 	STRUCT
		PLCopenState : McTrkPathPLCopenStateEnum; (*TrackingPath PLCopen state*)
		TrackingFrameCount : UINT; (*Number of tracking frames currently existing in TrackingPath*)
		TrackingFrameLimitReached : BOOL; (* Configured maximum number of tracking frames reached*)
		TrackingPathEstimatedMotionState : McTrkPathEstimatedMotionState; (*Estimated TrackingPath motion state*)
		AxisCommandConsideration : McTrkPathAxisCmdConsiderType; (*Config of Axis Command Consideration*)
		PositionError : LREAL; (**)
	END_STRUCT;
	McTrkPathAxisCmdConsiderType : STRUCT (*Configuration of Axis Command Consideration*)
		Active : BOOL; (*De- and activate*)
		BasicCommands : McTrkPathBasicCmdConsiderType; (*Considered movement type and target value*)
	END_STRUCT;
	McTrkPathBasicCmdConsiderType : STRUCT (*Configuration of Basic commands*)
		CurrentMovementType : McTrkPathBasicCmdConsiderEnum; (*position or velocity*)
		TargetValue : LREAL; (*target value*)
	END_STRUCT;
END_TYPE
