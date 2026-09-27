VAR CONSTANT 
P099 : McPointType := (Pos:=(X:=280, Y:=0, Z:=525),  Orient:=(Angle1 := -5, Angle2 := 4)); 
P001 : McPointType := (Pos:=(X:=350, Y:=-60, Z:=500),  Orient:=(Angle1 := -5, Angle2 := 4)); 
P002 : McPointType := (Pos:=(X:=350, Y:=-60, Z:=400));                               
P003 : McPointType := (Pos:=(X:=410, Y:=-65, Z:=300));
P004 : McPointType := (Pos:=(X:=350, Y:=-60, Z:=300), Orient:=(Angle1 := -5, Angle2 := 4));
P005 : McPointType := (Pos:=(X:=350, Y:=-60, Z:=500));
P006 : McPointType := (Pos:=(X:=400, Y:=-200, Z:=500));
P007 : McPointType := (Pos:=(X:=450, Y:=-350, Z:=303));
P008 : McPointType := (Pos:=(X:=450, Y:=-350, Z:=400));	

END_VAR  

	PROGRAM _MAIN          
	
	Feedrate(40 * 40);
	MoveL(P099);//        
	MoveL(P001);
	DO_PATH_SYNCH
	GripperClose:= FALSE;
	GripperOpen:= TRUE;
	END_PATH_SYNCH
	MoveL(P002);
	WaitTime(1);
	MoveL(P003);
	DO_PATH_SYNCH
	GripperClose:= TRUE;
	GripperOpen:= FALSE;
	END_PATH_SYNCH     
	WaitTime(1);
	MoveL(P004);
	WaitTime(1);
	MoveL(P005);
	MoveL(P006);
	MoveL(P007);
	DO_PATH_SYNCH
	GripperClose:= FALSE;
	GripperOpen:= TRUE;
	END_PATH_SYNCH
	MoveL(P007);
	WaitTime(1);
	MoveL(P008);
	WaitTime(1);
	MoveL(P099);
	END_PROGRAM