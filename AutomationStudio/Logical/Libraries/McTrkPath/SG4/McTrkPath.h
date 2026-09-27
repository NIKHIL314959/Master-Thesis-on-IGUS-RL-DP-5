/* Automation Studio generated header file */
/* Do not edit ! */
/* McTrkPath 5.31.0 */

#ifndef _MCTRKPATH_
#define _MCTRKPATH_
#ifdef __cplusplus
extern "C" 
{
#endif
#ifndef _McTrkPath_VERSION
#define _McTrkPath_VERSION 5.31.0
#endif

#include <bur/plctypes.h>

#ifndef _BUR_PUBLIC
#define _BUR_PUBLIC
#endif

#ifdef _SG4
#include <McBase.h> 
#include <MpBase.h>
#endif
 
#ifdef _SG3
#include <McBase.h> 
#include <MpBase.h>
#endif
 
#ifdef _SGC
#include <McBase.h> 
#include <MpBase.h>
#endif

/* Datatypes and datatypes of function blocks */
typedef enum McTrkPathPLCopenStateEnum
{	mcTRKPATH_STARTUP,
	mcTRKPATH_READY,
	mcTRKPATH_ERRORSTOP,
	mcTRKPATH_INVALID_CONFIGURATION
} McTrkPathPLCopenStateEnum;

typedef enum McTrkFrmGetModEnum
{	mcTRKPATH_GET_MOD_ALL_FRAMES = 0,
	mcTRKPATH_GET_MOD_CERTAIN_FRAME = 1
} McTrkFrmGetModEnum;

typedef enum McTrkFrmInfoModEnum
{	mcTRKPATH_INFO_MOD_ALL = 0,
	mcTRKPATH_INFO_MOD_ID_ONLY = 1,
	mcTRKPATH_INFO_MOD_POSE = 2,
	mcTRKPATH_INFO_MOD_DIST = 3,
	mcTRKPATH_INFO_MOD_POSE_DIST = 4
} McTrkFrmInfoModEnum;

typedef enum McTrkFrmDeleteModEnum
{	mcTRKFRM_DELETE_MOD_FRAME = 0,
	mcTRKFRM_DELETE_MOD_ALL = 1
} McTrkFrmDeleteModEnum;

typedef enum McTrkPathBasicCmdConsiderEnum
{	mcTRKPATH_AXCMDC_NOT_SUPPORTED = 0,
	mcTRKPATH_AXCMDC_TARGET_POS = 1,
	mcTRKPATH_AXCMDC_TARGET_VEL = 2
} McTrkPathBasicCmdConsiderEnum;

typedef enum McTPTypEnum
{	mcTPT_LIN = 0
} McTPTypEnum;

typedef enum McTPLinMotSrcEnum
{	mcTPTLMS_POS_PROC_VAR = 0,
	mcTPTLMS_AX = 1
} McTPLinMotSrcEnum;

typedef enum McTPLinMotSrcPosPVMoveLimEnum
{	mcTPTLMSPPVML_INT = 0
} McTPLinMotSrcPosPVMoveLimEnum;

typedef enum McTPLMSPPVMLIVelEnum
{	mcTPTLMSPPVMLIV_BASIC = 0
} McTPLMSPPVMLIVelEnum;

typedef enum McTPLMSPPVMLIAccEnum
{	mcTPTLMSPPVMLIA_BASIC = 0
} McTPLMSPPVMLIAccEnum;

typedef enum McTPLinMotSrcPosPVPrepEnum
{	mcTPTLMSPPVP_NO_PREP = 0,
	mcTPTLMSPPVP_LIN_REG = 1
} McTPLinMotSrcPosPVPrepEnum;

typedef enum McTPLinMotSrcAxAxUseEnum
{	mcTPTLMSAAU_ACT = 0,
	mcTPTLMSAAU_PASS = 1
} McTPLinMotSrcAxAxUseEnum;

typedef enum McTPLinCCEnum
{	mcTPLINCC_NOT_USE = 0,
	mcTPLINCC_SPT_BASIC_CMD = 1
} McTPLinCCEnum;

typedef enum McTPLinMotSrcAxMoveLimEnum
{	mcTPTLMSAML_USE_AX_LIM = 0,
	mcTPTLMSAML_INT = 1
} McTPLinMotSrcAxMoveLimEnum;

typedef enum McTPLMSAMLIVelEnum
{	mcTPTLMSAMLIV_BASIC = 0
} McTPLMSAMLIVelEnum;

typedef enum McTPLMSAMLIAccEnum
{	mcTPTLMSAMLIA_BASIC = 0
} McTPLMSAMLIAccEnum;

typedef enum McTPLinMotSrcAxPrepEnum
{	mcTPTLMSAP_NO_PREP = 0,
	mcTPTLMSAP_LIN_REG = 1
} McTPLinMotSrcAxPrepEnum;

typedef enum McTPSVEnum
{	mcTPSSVO_USE = 0,
	mcTPSSVO_NOT_USE = 1
} McTPSVEnum;

typedef enum McTPSVUseNameEnum
{	mcTPSSVOUN_VIS = 0,
	mcTPSSVOUN_INVIS = 1
} McTPSVUseNameEnum;

typedef enum McTPSVUseFrmEnum
{	mcTPSSVOUF_VIS = 0,
	mcTPSSVOUF_INVIS = 1
} McTPSVUseFrmEnum;

typedef enum McTPSVUseVREnum
{	mcTPSSVOUVR_NOT_USE = 0,
	mcTPSSVOUVR_CUBE = 1,
	mcTPSSVOUVR_CNVR_BELT = 2
} McTPSVUseVREnum;

typedef enum McTPSVUseContEnum
{	mcTPSSVOUC_NOT_USE = 0,
	mcTPSSVOUC_VIS = 1
} McTPSVUseContEnum;

typedef unsigned long McTrkFrmIdentType;

typedef struct McTrkFrmInfoType
{	McTrkFrmIdentType TrackingFrameID;
	struct McPosType CurrentPosition;
	struct McOrientType CurrentOrientation;
	double Distance;
	unsigned long Attribute;
} McTrkFrmInfoType;

typedef struct McTrkFramesCreateParType
{	unsigned long DataAddress;
	unsigned short NumberOfFrames;
} McTrkFramesCreateParType;

typedef struct McTrkFrmLatPathType
{	double Position;
} McTrkFrmLatPathType;

typedef struct McTrkFrmCreateParType
{	struct McTrkFrmLatPathType LatchedPath;
	struct McPosType Translation;
	struct McOrientType Orientation;
	unsigned long Attribute;
} McTrkFrmCreateParType;

typedef struct McTrkPathGetFrmParType
{	enum McTrkFrmGetModEnum GetMode;
	enum McTrkFrmInfoModEnum InfoMode;
	McTrkFrmIdentType TrackingFrameID;
	unsigned long CoordSystem;
	unsigned long DataAddress;
	unsigned short NumberOfFrames;
} McTrkPathGetFrmParType;

typedef struct McTrkPathEstimatedMotionState
{	double Position;
	float Velocity;
} McTrkPathEstimatedMotionState;

typedef struct McTrkPathBasicCmdConsiderType
{	enum McTrkPathBasicCmdConsiderEnum CurrentMovementType;
	double TargetValue;
} McTrkPathBasicCmdConsiderType;

typedef struct McTrkPathAxisCmdConsiderType
{	plcbit Active;
	struct McTrkPathBasicCmdConsiderType BasicCommands;
} McTrkPathAxisCmdConsiderType;

typedef struct McTrkPathInfoType
{	enum McTrkPathPLCopenStateEnum PLCopenState;
	unsigned short TrackingFrameCount;
	plcbit TrackingFrameLimitReached;
	struct McTrkPathEstimatedMotionState TrackingPathEstimatedMotionState;
	struct McTrkPathAxisCmdConsiderType AxisCommandConsideration;
	double PositionError;
} McTrkPathInfoType;

typedef struct McTPLMSPPVMLIVelBasicType
{	float Velocity;
} McTPLMSPPVMLIVelBasicType;

typedef struct McTPLMSPPVMLIVelType
{	enum McTPLMSPPVMLIVelEnum Type;
	struct McTPLMSPPVMLIVelBasicType Basic;
} McTPLMSPPVMLIVelType;

typedef struct McTPLMSPPVMLIAccBasicType
{	float Acceleration;
} McTPLMSPPVMLIAccBasicType;

typedef struct McTPLMSPPVMLIAccType
{	enum McTPLMSPPVMLIAccEnum Type;
	struct McTPLMSPPVMLIAccBasicType Basic;
} McTPLMSPPVMLIAccType;

typedef struct McTPLMSPPVMLIType
{	struct McTPLMSPPVMLIVelType Velocity;
	struct McTPLMSPPVMLIAccType Acceleration;
} McTPLMSPPVMLIType;

typedef struct McTPLinMotSrcPosPVMoveLimType
{	enum McTPLinMotSrcPosPVMoveLimEnum Type;
	struct McTPLMSPPVMLIType Internal;
} McTPLinMotSrcPosPVMoveLimType;

typedef struct McTPLinMotSrcPosPVPrepLinRegType
{	signed long ConsideredSamples;
	double PositionDisturbance;
} McTPLinMotSrcPosPVPrepLinRegType;

typedef struct McTPLinMotSrcPosPVPrepType
{	enum McTPLinMotSrcPosPVPrepEnum Type;
	struct McTPLinMotSrcPosPVPrepLinRegType LinearRegression;
} McTPLinMotSrcPosPVPrepType;

typedef struct McTPLinMotSrcPosPVType
{	plcstring ProcessVariableName[251];
	double NegativeOverflow;
	double PositiveOverflow;
	double DelayTime;
	struct McTPLinMotSrcPosPVMoveLimType MovementLimits;
	struct McTPLinMotSrcPosPVPrepType Preparation;
} McTPLinMotSrcPosPVType;

typedef struct McTPLinCCType
{	enum McTPLinCCEnum Type;
} McTPLinCCType;

typedef struct McTPLinMotSrcAxAxUseActType
{	struct McTPLinCCType CommandConsideration;
} McTPLinMotSrcAxAxUseActType;

typedef struct McTPLinMotSrcAxAxUseType
{	enum McTPLinMotSrcAxAxUseEnum Type;
	struct McTPLinMotSrcAxAxUseActType Active;
} McTPLinMotSrcAxAxUseType;

typedef struct McTPLMSAMLIVelBasicType
{	float Velocity;
} McTPLMSAMLIVelBasicType;

typedef struct McTPLMSAMLIVelType
{	enum McTPLMSAMLIVelEnum Type;
	struct McTPLMSAMLIVelBasicType Basic;
} McTPLMSAMLIVelType;

typedef struct McTPLMSAMLIAccBasicType
{	float Acceleration;
} McTPLMSAMLIAccBasicType;

typedef struct McTPLMSAMLIAccType
{	enum McTPLMSAMLIAccEnum Type;
	struct McTPLMSAMLIAccBasicType Basic;
} McTPLMSAMLIAccType;

typedef struct McTPLMSAMLIType
{	struct McTPLMSAMLIVelType Velocity;
	struct McTPLMSAMLIAccType Acceleration;
} McTPLMSAMLIType;

typedef struct McTPLinMotSrcAxMoveLimType
{	enum McTPLinMotSrcAxMoveLimEnum Type;
	struct McTPLMSAMLIType Internal;
} McTPLinMotSrcAxMoveLimType;

typedef struct McTPLinMotSrcAxPrepLinRegType
{	signed long ConsideredSamples;
	double PositionDisturbance;
} McTPLinMotSrcAxPrepLinRegType;

typedef struct McTPLinMotSrcAxPrepType
{	enum McTPLinMotSrcAxPrepEnum Type;
	struct McTPLinMotSrcAxPrepLinRegType LinearRegression;
} McTPLinMotSrcAxPrepType;

typedef struct McTPLinMotSrcAxType
{	struct McCfgReferenceType AxisReference;
	struct McTPLinMotSrcAxAxUseType AxisUsage;
	double DelayTime;
	struct McTPLinMotSrcAxMoveLimType MovementLimits;
	struct McTPLinMotSrcAxPrepType Preparation;
} McTPLinMotSrcAxType;

typedef struct McTPLinMotSrcType
{	enum McTPLinMotSrcEnum Type;
	struct McTPLinMotSrcPosPVType PositionProcessVariable;
	struct McTPLinMotSrcAxType Axis;
} McTPLinMotSrcType;

typedef struct McTPLinType
{	unsigned short MaxTrackingFrames;
	double MaxPositionError;
	struct McTPLinMotSrcType MotionSource;
} McTPLinType;

typedef struct McTPTypType
{	enum McTPTypEnum Type;
	struct McTPLinType Linear;
} McTPTypType;

typedef struct McCfgTrkPathType
{	struct McTPTypType Type;
} McCfgTrkPathType;

typedef struct McTPSVUseNameType
{	enum McTPSVUseNameEnum Type;
} McTPSVUseNameType;

typedef struct McTPSVUseFrmType
{	enum McTPSVUseFrmEnum Type;
} McTPSVUseFrmType;

typedef struct McTPSVUseVRCubeDimType
{	double Length;
	double Width;
	double Height;
} McTPSVUseVRCubeDimType;

typedef struct McTPSVUseVRCubeType
{	struct McTPSVUseVRCubeDimType Dimensions;
	struct McCfgTransXYZType Translation;
	struct McCfgOrientType Orientation;
	enum McScnSurfaceEnum Material;
} McTPSVUseVRCubeType;

typedef struct McTPSVUseVRCnvrBeltDimType
{	double Length;
	double Width;
	double Height;
} McTPSVUseVRCnvrBeltDimType;

typedef struct McTPSVUseVRCnvrBeltType
{	struct McTPSVUseVRCnvrBeltDimType Dimensions;
	struct McCfgTransXYZType Translation;
	struct McCfgOrientType Orientation;
	enum McScnSurfaceEnum Material;
} McTPSVUseVRCnvrBeltType;

typedef struct McTPSVUseVRType
{	enum McTPSVUseVREnum Type;
	struct McTPSVUseVRCubeType Cuboid;
	struct McTPSVUseVRCnvrBeltType ConveyorBelt;
} McTPSVUseVRType;

typedef struct McTPSVUseContType
{	enum McTPSVUseContEnum Type;
} McTPSVUseContType;

typedef struct McTPSVUseType
{	struct McTPSVUseNameType Name;
	struct McTPSVUseFrmType Frame;
	struct McTPSVUseVRType VisualRepresentation;
	struct McTPSVUseContType Content;
} McTPSVUseType;

typedef struct McTPSVType
{	enum McTPSVEnum Type;
	struct McTPSVUseType Used;
} McTPSVType;

typedef struct McCfgTrkPathScnType
{	struct McTPSVType SceneViewerObject;
} McCfgTrkPathScnType;

typedef struct MC_BR_TrackingFramesCreate
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	struct McTrkFramesCreateParType Parameters;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingFramesCreate_typ;

typedef struct MC_BR_TrackingFrameCreate
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	struct McTrkFrmCreateParType Parameters;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	McTrkFrmIdentType TrackingFrameID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingFrameCreate_typ;

typedef struct MC_BR_TrackingFrameDelete
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	enum McTrkFrmDeleteModEnum Mode;
	McTrkFrmIdentType TrackingFrameID;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingFrameDelete_typ;

typedef struct MC_BR_TrackingPathGetFrames
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	struct McTrkPathGetFrmParType Parameters;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	unsigned short TrackingFrameCount;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingPathGetFrames_typ;

typedef struct MC_BR_TrackingFrameSetAttribute
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	McTrkFrmIdentType TrackingFrameID;
	unsigned long Attribute;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingFrameSetAttribute_typ;

typedef struct MC_BR_TrackingPathReadStatus
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Enable;
	/* VAR_OUTPUT (digital) */
	plcbit Valid;
	plcbit Busy;
	plcbit Error;
	plcbit TrackingPathReady;
	plcbit TrackingPathErrorStop;
} MC_BR_TrackingPathReadStatus_typ;

typedef struct MC_BR_TrackingPathReadInfo
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	struct McTrkPathInfoType TrackingPathInfo;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Enable;
	/* VAR_OUTPUT (digital) */
	plcbit Valid;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingPathReadInfo_typ;

typedef struct MC_BR_TrackingPathReset
{
	/* VAR_INPUT (analog) */
	struct McTrackingPathType* TrackingPath;
	/* VAR_OUTPUT (analog) */
	signed long ErrorID;
	/* VAR (analog) */
	struct McInternalType Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} MC_BR_TrackingPathReset_typ;



/* Prototyping of functions and function blocks */
_BUR_PUBLIC void MC_BR_TrackingFramesCreate(struct MC_BR_TrackingFramesCreate* inst);
_BUR_PUBLIC void MC_BR_TrackingFrameCreate(struct MC_BR_TrackingFrameCreate* inst);
_BUR_PUBLIC void MC_BR_TrackingFrameDelete(struct MC_BR_TrackingFrameDelete* inst);
_BUR_PUBLIC void MC_BR_TrackingPathGetFrames(struct MC_BR_TrackingPathGetFrames* inst);
_BUR_PUBLIC void MC_BR_TrackingFrameSetAttribute(struct MC_BR_TrackingFrameSetAttribute* inst);
_BUR_PUBLIC void MC_BR_TrackingPathReadStatus(struct MC_BR_TrackingPathReadStatus* inst);
_BUR_PUBLIC void MC_BR_TrackingPathReadInfo(struct MC_BR_TrackingPathReadInfo* inst);
_BUR_PUBLIC void MC_BR_TrackingPathReset(struct MC_BR_TrackingPathReset* inst);


#ifdef __cplusplus
};
#endif
#endif /* _MCTRKPATH_ */

