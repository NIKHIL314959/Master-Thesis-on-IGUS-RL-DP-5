VAR{AT 'Program'}
	

GripperClose: BOOL;
GripperOpen: BOOL;	

	END_VAR

	PROGRAM _MAIN


	DO_PATH_SYNCH
	GripperClose:= TRUE;
	GripperOpen:= FALSE;
	END_PATH_SYNCH

	END_PROGRAM