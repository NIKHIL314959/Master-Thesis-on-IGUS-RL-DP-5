
TYPE
	VarsHomingSwitchTrigger_typ : 	STRUCT  (*Homing trigger for all axis*)
		Axis1 : BOOL; (*Homing trigger axis 1*)
		Axis2 : BOOL; (*Homing trigger axis 2*)
		Axis3 : BOOL; (*Homing trigger axis 3*)
		Axis4 : BOOL; (*Homing trigger axis 4*)
		Axis5 : BOOL; (*Homing trigger axis 5*)
	END_STRUCT;
	JogDirection_typ : 	STRUCT 
		Positive : BOOL;
		Negative : BOOL;
	END_STRUCT;
	GoToState_typ : 	STRUCT  (*Vars from visu*)
		Tipping : BOOL; (*Go to tipping state*)
		GCode : BOOL; (*Go to G-Code state*)
		MoveSetPos : BOOL; (*Go to MoveSetPos state*)
	END_STRUCT;
	HomingCount_enum : 
		(
		NoHoming := 0,
		DefaultHomingDone := 1,
		DirectHomingDone := 2
		);
	Pars_typ : 	STRUCT 
		PosMCS : ARRAY[0..4]OF LREAL;
	END_STRUCT;
	Cmd_typ : 	STRUCT 
		PowerOn : BOOL;
		Home : BOOL;
		Stop : BOOL;
		Start : BOOL;
		ErrorReset : BOOL;
		MoveIndex : BOOL;
	END_STRUCT;
	StateMachine_enum : 
		(
		STATE_Disabled := 0,
		STATE_PowerOn := 5,
		STATE_WaitForHome := 9,
		STATE_Home := 10,
		STATE_Idle := 20,
		STATE_Tipping := 40,
		STATE_Error := 99,
		STATE_MoveSetPos := 50
		);
	MainPar_typ : 	STRUCT 
		StateMachine : StateMachine_enum;
		PreStateIdent : StateMachine_enum;
		Cmd : Cmd_typ;
		HomingCount : HomingCount_enum;
		Status : Status_enum;
		GoToState : GoToState_typ;
	END_STRUCT;
	Status_enum : 
		(
		Disabled,
		Idle,
		State_Active,
		State_Error
		);
END_TYPE
