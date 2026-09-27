(*
================================================================================
  Main.st — Cyclic program for the robot arm
  Hardware : B&R X20CP0484-1 + Igus RL-DP-5
  mapp Motion : 5.22.2  |  Automation Runtime : B4.93

MATLAB sends Cartisian targets (X,Y,Z,B,C) over OPC UA
The PLC handles all kinematics via MpRoboArm5Axis
MpAxisBasic handles per-axis power and homing
================================================================================
*)

PROGRAM _CYCLIC

    // =========================================================================
    // 1. FIRST CYCLE INITIALIZATION
    // =========================================================================
	IF NOT initDone THEN

		// -- Link each axis FB to its configured axis --
		fbMpAxisBasic[0].MpLink     := ADR(gAxisQ1);
		fbMpAxisBasic[1].MpLink     := ADR(gAxisQ2);
		fbMpAxisBasic[2].MpLink     := ADR(gAxisQ3);
		fbMpAxisBasic[3].MpLink     := ADR(gAxisQ4);
		fbMpAxisBasic[4].MpLink     := ADR(gAxisQ5);

		// -- Enable all axes, set default homing --
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].Enable     := TRUE;
			fbMpAxisBasic[i].Parameters := ADR(ParAxis[i]);
			ParAxis[i].Velocity         := gParam_Velocity;
			ParAxis[i].Homing.Mode      := mcHOMING_DEFAULT;
		END_FOR;

		// -- MpRoboArm5Axis setup --
		MpRoboArm5Axis_0.MpLink     := ADR(g5AxRobA);
		MpRoboArm5Axis_0.Parameters := ADR(RoboParameters);
		MpRoboArm5Axis_0.Enable     := TRUE;
		MpRoboArm5Axis_0.Override   := 100.0;

		// -- Initialize RoboParameters --
		RoboParameters.CoordSystem    := mcMCS;
		RoboParameters.Velocity     := gParam_Velocity;
		RoboParameters.Acceleration := gParam_Acceleration;
		RoboParameters.Deceleration := gParam_Acceleration;
		RoboParameters.Position[0]  := 0.0;
		RoboParameters.Position[1]  := 0.0;
		RoboParameters.Position[2]  := 0.0;
		RoboParameters.Position[3]  := 0.0;
		RoboParameters.Position[4]  := 0.0;

		// -- Clean command state --
		gCmd_MoveLinear := FALSE;
		gCmd_MoveDirect := FALSE;
		gCmd_Stop       := FALSE;
		gCmd_ErrorReset := FALSE;
		gCmd_Home       := FALSE;

		initDone := TRUE;
	END_IF;

	// =========================================================================
	// 2. ENABLE ALL AXIS BASIC FBs EVERY CYCLE
	// =========================================================================
	FOR i := 0 TO 4 DO
		fbMpAxisBasic[i].Enable := TRUE;
	END_FOR;

	// =========================================================================
	// 3. ENABLE MpRoboArm5Axis EVERY CYCLE
	// =========================================================================
	MpRoboArm5Axis_0.Enable   := TRUE;
	MpRoboArm5Axis_0.Override := gParam_Override;

	// =========================================================================
	// 4. PARAMETER SYNC
	// =========================================================================
	RoboParameters.Velocity     := gParam_Velocity;
	RoboParameters.Acceleration := gParam_Acceleration;
	RoboParameters.Deceleration := gParam_Acceleration;

	FOR i := 0 TO 4 DO
		ParAxis[i].Velocity := gParam_Velocity;
	END_FOR;

	// =========================================================================
	// 5. E-STOP HANDLING
	// =========================================================================
	gEStop_Active := NOT gEStop_OK;

	IF gEStop_Active THEN
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].Stop := TRUE;
		END_FOR;
		MpRoboArm5Axis_0.Stop   := TRUE;
		gCmd_MoveLinear         := FALSE;
		gCmd_MoveDirect         := FALSE;
		gCmd_Stop               := FALSE;
	ELSE
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].Stop := FALSE;
		END_FOR;
		MpRoboArm5Axis_0.Stop := FALSE;
	END_IF;

	// =========================================================================
	// 6. ERROR RESET
	// =========================================================================
	trigErrorReset(CLK := gCmd_ErrorReset);
	IF trigErrorReset.Q THEN
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].ErrorReset := TRUE;
		END_FOR;
		MpRoboArm5Axis_0.ErrorReset := TRUE;
		gCmd_ErrorReset             := FALSE;
	ELSE
		FOR i := 0 TO 4 DO
			IF fbMpAxisBasic[i].ErrorReset AND NOT fbMpAxisBasic[i].Error THEN
				fbMpAxisBasic[i].ErrorReset := FALSE;
			END_IF;
		END_FOR;
		IF MpRoboArm5Axis_0.ErrorReset AND NOT MpRoboArm5Axis_0.Error THEN
			MpRoboArm5Axis_0.ErrorReset := FALSE;
		END_IF;
	END_IF;

	// =========================================================================
	// 6b. HOMING COMMAND — triggered by MATLAB Home button via OPC UA
	// =========================================================================
	trigHome(CLK := gCmd_Home);
	IF trigHome.Q THEN
		gCmd_Home      := FALSE;
		gStatus_Homing := TRUE;
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].Home := TRUE;
		END_FOR;
	END_IF;

	// =========================================================================
	// 7. COMMAND PROCESSING — MOVE LINEAR
	// =========================================================================
	trigMoveLinear(CLK := gCmd_MoveLinear);

	IF trigMoveLinear.Q THEN
		gCmd_MoveLinear := FALSE;

		IF gEStop_Active THEN
			// Reject: E-stop

		ELSIF NOT gStatus_Homed THEN
			gStatus_Error   := TRUE;
			gStatus_ErrorID := -1;  // not homed

		ELSIF MpRoboArm5Axis_0.Error THEN
			// Reject: error state

		ELSIF NOT MpRoboArm5Axis_0.PowerOn THEN
			gStatus_Error   := TRUE;
			gStatus_ErrorID := -2;  // power not on

		ELSE
			RoboParameters.Position[0]  := gTargetX;
			RoboParameters.Position[1]  := gTargetY;
			RoboParameters.Position[2]  := gTargetZ;
			RoboParameters.Position[3]  := gTargetB;
			RoboParameters.Position[4]  := gTargetC;

			gStatus_InPosition          := FALSE;
			MpRoboArm5Axis_0.MoveLinear := TRUE;
			MpRoboArm5Axis_0.MoveDirect := FALSE;
		END_IF;
	END_IF;

	// =========================================================================
	// 8. COMMAND PROCESSING — MOVE DIRECT
	// =========================================================================
	trigMoveDirect(CLK := gCmd_MoveDirect);

	IF trigMoveDirect.Q THEN
		gCmd_MoveDirect := FALSE;

		IF gEStop_Active THEN
			// Reject

		ELSIF NOT gStatus_Homed THEN
			gStatus_Error   := TRUE;
			gStatus_ErrorID := -1;

		ELSIF MpRoboArm5Axis_0.Error THEN
			// Reject

		ELSIF NOT MpRoboArm5Axis_0.PowerOn THEN
			gStatus_Error   := TRUE;
			gStatus_ErrorID := -2;

		ELSE
			RoboParameters.Position[0]  := gTargetX;
			RoboParameters.Position[1]  := gTargetY;
			RoboParameters.Position[2]  := gTargetZ;
			RoboParameters.Position[3]  := gTargetB;
			RoboParameters.Position[4]  := gTargetC;

			gStatus_InPosition          := FALSE;
			MpRoboArm5Axis_0.MoveDirect := TRUE;
			MpRoboArm5Axis_0.MoveLinear := FALSE;
		END_IF;
	END_IF;

	// =========================================================================
	// 8b. COMMAND PROCESSING — JOINT JOG (ACS — single joint only)
	// =========================================================================
	trigJogJoint(CLK := gCmd_JogJoint);
	IF trigJogJoint.Q THEN
		gCmd_JogJoint := FALSE;

		IF NOT gEStop_Active AND NOT MpRoboArm5Axis_0.Error
			AND gStatus_PowerOn AND gStatus_Homed THEN

			RoboParameters.CoordSystem := mcACS;

			RoboParameters.Position[0] := MpRoboArm5Axis_0.Info.JointAxisPosition[0];
			RoboParameters.Position[1] := MpRoboArm5Axis_0.Info.JointAxisPosition[1];
			RoboParameters.Position[2] := MpRoboArm5Axis_0.Info.JointAxisPosition[2];
			RoboParameters.Position[3] := MpRoboArm5Axis_0.Info.JointAxisPosition[3];
			RoboParameters.Position[4] := MpRoboArm5Axis_0.Info.JointAxisPosition[4];

			CASE gJogJointIndex OF
				1: RoboParameters.Position[0] := RoboParameters.Position[0] + gJogJointStep;
				2: RoboParameters.Position[1] := RoboParameters.Position[1] + gJogJointStep;
				3: RoboParameters.Position[2] := RoboParameters.Position[2] + gJogJointStep;
				4: RoboParameters.Position[3] := RoboParameters.Position[3] + gJogJointStep;
				5: RoboParameters.Position[4] := RoboParameters.Position[4] + gJogJointStep;
			END_CASE;

			gStatus_InPosition          := FALSE;
			MpRoboArm5Axis_0.MoveLinear := FALSE;
			MpRoboArm5Axis_0.MoveDirect := TRUE;
		END_IF;
	END_IF;

	// =========================================================================
	// 9. COMMAND PROCESSING — STOP
	// =========================================================================
	trigStop(CLK := gCmd_Stop);
	IF trigStop.Q THEN
		gCmd_Stop                   := FALSE;
		MpRoboArm5Axis_0.MoveLinear := FALSE;
		MpRoboArm5Axis_0.MoveDirect := FALSE;
		MpRoboArm5Axis_0.Stop       := TRUE;
	END_IF;

	IF MpRoboArm5Axis_0.Stop AND NOT gEStop_Active THEN
		MpRoboArm5Axis_0.Stop := FALSE;
	END_IF;

	// =========================================================================
	// 10. MOVE COMPLETION DETECTION
	// =========================================================================
	IF MpRoboArm5Axis_0.MoveLinear OR MpRoboArm5Axis_0.MoveDirect THEN
		IF MpRoboArm5Axis_0.MoveDone THEN
			MpRoboArm5Axis_0.MoveLinear := FALSE;
			MpRoboArm5Axis_0.MoveDirect := FALSE;
			gStatus_InPosition          := TRUE;
			gStatus_Moving              := FALSE;
		ELSIF MpRoboArm5Axis_0.Error OR MpRoboArm5Axis_0.CommandAborted THEN
			MpRoboArm5Axis_0.MoveLinear := FALSE;
			MpRoboArm5Axis_0.MoveDirect := FALSE;
			gStatus_Moving              := FALSE;
		ELSE
			gStatus_Moving     := TRUE;
			gStatus_InPosition := FALSE;
		END_IF;
	END_IF;

	RoboParameters.CoordSystem := mcMCS;

	// =========================================================================
	// 11. CALL MpAxisBasic FOR ALL 5 JOINTS EVERY CYCLE
	// =========================================================================
	FOR i := 0 TO 4 DO
		fbMpAxisBasic[i]();
	END_FOR;

	// =========================================================================
	// 12. CALL MpRoboArm5Axis EVERY CYCLE
	// =========================================================================
	MpRoboArm5Axis_0();

	// =========================================================================
	// 13. STATUS OUTPUT PUBLISHING
	// =========================================================================
	allAxesHomed := fbMpAxisBasic[0].IsHomed AND fbMpAxisBasic[1].IsHomed
	AND fbMpAxisBasic[2].IsHomed AND fbMpAxisBasic[3].IsHomed
	AND fbMpAxisBasic[4].IsHomed;

	allAxesPowered := fbMpAxisBasic[0].PowerOn AND fbMpAxisBasic[1].PowerOn
	AND fbMpAxisBasic[2].PowerOn AND fbMpAxisBasic[3].PowerOn
	AND fbMpAxisBasic[4].PowerOn;

	gStatus_Homed   := MpRoboArm5Axis_0.IsHomed AND allAxesHomed;
	gStatus_PowerOn := MpRoboArm5Axis_0.PowerOn AND allAxesPowered;
	gStatus_Ready   := gStatus_PowerOn AND gStatus_Homed
	AND NOT MpRoboArm5Axis_0.Error;

	IF MpRoboArm5Axis_0.Error THEN
		gStatus_Error   := TRUE;
		gStatus_ErrorID := MpRoboArm5Axis_0.StatusID;
	ELSIF NOT gEStop_Active THEN
		gStatus_Error   := FALSE;
		gStatus_ErrorID := 0;
	END_IF;
	
	// Clear Home trigger once all axes finish homing
	IF gStatus_Homing AND allAxesHomed THEN
		FOR i := 0 TO 4 DO
			fbMpAxisBasic[i].Home := FALSE;
		END_FOR;
		gStatus_Homing := FALSE;
	END_IF;

	// =========================================================================
	// 14. ACTUAL POSITION FEEDBACK
	// =========================================================================
	gActual_X := MpRoboArm5Axis_0.X;
	gActual_Y := MpRoboArm5Axis_0.Y;
	gActual_Z := MpRoboArm5Axis_0.Z;
	gActual_B := MpRoboArm5Axis_0.B;
	gActual_C := MpRoboArm5Axis_0.C;

	gActual_Q1 := MpRoboArm5Axis_0.Info.JointAxisPosition[0];
	gActual_Q2 := MpRoboArm5Axis_0.Info.JointAxisPosition[1];
	gActual_Q3 := MpRoboArm5Axis_0.Info.JointAxisPosition[2];
	gActual_Q4 := MpRoboArm5Axis_0.Info.JointAxisPosition[3];
	gActual_Q5 := MpRoboArm5Axis_0.Info.JointAxisPosition[4];

	gZeroedAngle_Q1 := -(gActual_Q1 - gAngleOffset_Q1);
	gZeroedAngle_Q2 := -(gActual_Q2 - gAngleOffset_Q2);
	gZeroedAngle_Q3 := -(gActual_Q3 - gAngleOffset_Q3);
	gZeroedAngle_Q4 := -(gActual_Q4 - gAngleOffset_Q4);
	gZeroedAngle_Q5 := -(gActual_Q5 - gAngleOffset_Q5);

	// =========================================================================
	// 15. TEACH POSITIONS — store actual TCP into pick/place/home variables
	// =========================================================================
	trigTeachPick(CLK := gCmd_TeachPick);
	IF trigTeachPick.Q THEN
		gCmd_TeachPick := FALSE;
		gPickX := MpRoboArm5Axis_0.X;
		gPickY := MpRoboArm5Axis_0.Y;
		gPickZ := MpRoboArm5Axis_0.Z;
		gPickB := MpRoboArm5Axis_0.B;
		gPickC := MpRoboArm5Axis_0.C;
	END_IF;

	trigTeachPlace(CLK := gCmd_TeachPlace);
	IF trigTeachPlace.Q THEN
		gCmd_TeachPlace := FALSE;
		gPlaceX := MpRoboArm5Axis_0.X;
		gPlaceY := MpRoboArm5Axis_0.Y;
		gPlaceZ := MpRoboArm5Axis_0.Z;
		gPlaceB := MpRoboArm5Axis_0.B;
		gPlaceC := MpRoboArm5Axis_0.C;
	END_IF;

	trigTeachHome(CLK := gCmd_TeachHome);
	IF trigTeachHome.Q THEN
		gCmd_TeachHome := FALSE;
		gHomeX := MpRoboArm5Axis_0.X;
		gHomeY := MpRoboArm5Axis_0.Y;
		gHomeZ := MpRoboArm5Axis_0.Z;
		gHomeB := MpRoboArm5Axis_0.B;
		gHomeC := MpRoboArm5Axis_0.C;
	END_IF;

	// =========================================================================
	// 16. PICK AND PLACE : Home --> above Pick --> Pick --> grip --> above Pick --> above Place --> Place --> release --> above Place --> Home
	//     PP_OFFSET      : safe height above pick / place
	//     ppGripperDelay : wait counter for gripper to settle (~300 cycles)
	// =========================================================================
	IF gCmd_PickPlace THEN
		CASE pickPlaceStep OF

			0:  // Start at home — open gripper
				gTargetX        := gHomeX;
				gTargetY        := gHomeY;
				gTargetZ        := gHomeZ;
				gTargetB        := gHomeB;
				gTargetC        := gHomeC;
				gCmd_MoveDirect := TRUE;
				gGripperOpen    := TRUE;
				gGripperClose   := FALSE;
				pickPlaceStep   := 1;

			1:  // Wait at home
				IF gStatus_InPosition THEN
					ppGripperDelay := ppGripperDelay + 1;
					IF ppGripperDelay >= 300 THEN
						ppGripperDelay := 0;
						pickPlaceStep  := 2;
					END_IF;
				END_IF;

			2:  // Move above pick point
				gTargetX        := gPickX;
				gTargetY        := gPickY;
				gTargetZ        := gPickZ + PP_OFFSET;
				gTargetB        := gPickB;
				gTargetC        := gPickC;
				gCmd_MoveDirect := TRUE;
				pickPlaceStep   := 3;

			3:  // Wait above pick
				IF gStatus_InPosition THEN
					pickPlaceStep := 4;
				END_IF;

			4:  // Lower straight down to pick point
				gTargetX        := gPickX;
				gTargetY        := gPickY;
				gTargetZ        := gPickZ;
				gTargetB        := gPickB;
				gTargetC        := gPickC;
				gCmd_MoveLinear := TRUE;
				pickPlaceStep   := 5;

			5:  // Wait at pick point
				IF gStatus_InPosition THEN
					pickPlaceStep := 6;
				END_IF;

			6:  // Close gripper — grip object
				gGripperClose     := TRUE;
				gGripperOpen      := FALSE;
				ppGripperDelay    := ppGripperDelay + 1;
				IF ppGripperDelay >= 300 THEN
					ppGripperDelay := 0;
					pickPlaceStep  := 7;
				END_IF;

			7:  // Lift straight up above pick
				gTargetX        := gPickX;
				gTargetY        := gPickY;
				gTargetZ        := gPickZ + PP_OFFSET;
				gTargetB        := gPickB;
				gTargetC        := gPickC;
				gCmd_MoveLinear := TRUE;
				pickPlaceStep   := 8;

			8:  // Wait above pick
				IF gStatus_InPosition THEN
					pickPlaceStep := 9;
				END_IF;

			9:  // Move across to above place point
				gTargetX        := gPlaceX;
				gTargetY        := gPlaceY;
				gTargetZ        := gPlaceZ + PP_OFFSET;
				gTargetB        := gPlaceB;
				gTargetC        := gPlaceC;
				gCmd_MoveDirect := TRUE;
				pickPlaceStep   := 10;

			10: // Wait above place
				IF gStatus_InPosition THEN
					pickPlaceStep := 11;
				END_IF;

			11: // Lower straight down to place point
				gTargetX        := gPlaceX;
				gTargetY        := gPlaceY;
				gTargetZ        := gPlaceZ;
				gTargetB        := gPlaceB;
				gTargetC        := gPlaceC;
				gCmd_MoveLinear := TRUE;
				pickPlaceStep   := 12;

			12: // Wait at place point
				IF gStatus_InPosition THEN
					pickPlaceStep := 13;
				END_IF;

			13: // Open gripper — release object
				gGripperOpen      := TRUE;
				gGripperClose     := FALSE;
				ppGripperDelay    := ppGripperDelay + 1;
				IF ppGripperDelay >= 300 THEN
					ppGripperDelay := 0;
					pickPlaceStep  := 14;
				END_IF;

			14: // Lift above place point
				gTargetX        := gPlaceX;
				gTargetY        := gPlaceY;
				gTargetZ        := gPlaceZ + PP_OFFSET;
				gTargetB        := gPlaceB;
				gTargetC        := gPlaceC;
				gCmd_MoveLinear := TRUE;
				pickPlaceStep   := 15;

			15: // Wait above place
				IF gStatus_InPosition THEN
					pickPlaceStep := 16;
				END_IF;

			16: // Return to home
				gTargetX        := gHomeX;
				gTargetY        := gHomeY;
				gTargetZ        := gHomeZ;
				gTargetB        := gHomeB;
				gTargetC        := gHomeC;
				gCmd_MoveDirect := TRUE;
				pickPlaceStep   := 17;

			17: // Wait at home — sequence complete
				IF gStatus_InPosition THEN
					gGripperOpen   := FALSE;
					gGripperClose  := FALSE;
					gCmd_PickPlace := FALSE;
					pickPlaceStep  := 0;
				END_IF;

		END_CASE;
	END_IF;

END_PROGRAM