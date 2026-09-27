VAR{AT 'Program'}
	

GripperClose: BOOL;
GripperOpen: BOOL;	

	END_VAR

	PROGRAM _MAIN


	DO_PATH_SYNCH
	GripperClose:= FALSE;
	GripperOpen:= TRUE;
	END_PATH_SYNCH

	END_PROGRAM
