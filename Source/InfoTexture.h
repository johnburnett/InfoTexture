#pragma once

#include "Max.h"

#if MAX_VERSION_MAJOR < 9	//Max 9
#include "max_mem.h"	//max 8 and earlier
#else
#include "maxheapdirect.h"
#endif

#include "iparamm2.h"

extern TCHAR* GetString(int id);

const Class_ID		kInfoTexture_ClassID		(0x2b3d38d2, 0x5cd7152f);
const Interface_ID	kInfoTexture_InterfaceID	(0x51340541, 0x43526a26);

enum
{
	kIt_pblock_params,
	kIt_pblock_count,
};

enum
{
	kIt_info_type,
	kIt_coord_sys,
	kIt_use_full_camera_normal_range,
	kIt_uvw_channel,
	kIt_wrap_mode,
	kIt_data_channel,
};

enum InfoType
{
	kInfoFaceIndex,
	kInfoBaryCoords,
	kInfoUvwCoords,
	kInfoNormal,
	kInfoReflectVector,
	kInfoRefractVector,
	kInfoObjectBoundingBox,
	kInfoVertexData,
	kInfoTypeCount,
};

enum WrapMode
{
	kWrapNone,
	kWrapClamp,
	kWrapRepeat,
	kWrapModeCount,
};

enum CoordSys
{
	kCoordSysCamera,
	kCoordSysWorld,
	kCoordSysObject,
	kCoordSysCount,
};

///////////////////////////////////////////////////////////////////////////////////////////////////

class IInfoTexture : public FPMixinInterface
{
public:
	enum FunctionIDs
	{
		fn_get_info_type,
		fn_set_info_type,
		fn_get_wrap_mode,
		fn_set_wrap_mode,
		fn_get_coord_sys,
		fn_set_coord_sys,
	};

	enum EnumTypeIDs
	{
		enum_info_type,
		enum_wrap_mode,
		enum_coord_sys,
	};

	BEGIN_FUNCTION_MAP
		PROP_FNS(fn_get_info_type, GetInfoType, fn_set_info_type, SetInfoType, TYPE_ENUM);
		PROP_FNS(fn_get_wrap_mode, GetWrapMode, fn_set_wrap_mode, SetWrapMode, TYPE_ENUM);
		PROP_FNS(fn_get_coord_sys, GetCoordSys, fn_set_coord_sys, SetCoordSys, TYPE_ENUM);
	END_FUNCTION_MAP

	FPInterfaceDesc*	GetDesc			();

	virtual int			GetInfoType		() = 0;
	virtual void		SetInfoType		(int infoType) = 0;

	virtual int			GetWrapMode		() = 0;
	virtual void		SetWrapMode		(int wrapMode) = 0;

	virtual int			GetCoordSys		() = 0;
	virtual void		SetCoordSys		(int coordSys) = 0;
};

///////////////////////////////////////////////////////////////////////////////////////////////////

class InfoTexture : public Texmap, public IInfoTexture
{
public:
	InfoTexture();

	// Animatable /////////////////////////////////////////////////////////////////////////////////

	void			GetClassName			(TSTR& s);

	Class_ID		ClassID					();
	SClass_ID		SuperClassID			();

	void			DeleteThis				();

	int				NumSubs					();
	Animatable*		SubAnim					(int i);
	TSTR			SubAnimName				(int i);

	int				NumParamBlocks			();
	IParamBlock2*	GetParamBlock			(int i);
	IParamBlock2*	GetParamBlockByID		(BlockID id);

	// ReferenceTarget ////////////////////////////////////////////////////////////////////////////

	RefTargetHandle	Clone					(RemapDir &remap);

	// ReferenceMaker /////////////////////////////////////////////////////////////////////////////

	int				NumRefs					();
	RefTargetHandle	GetReference			(int i);
#if MAX_VERSION_MAJOR < 14	//Max 2012
	void			SetReference			(int i, RefTargetHandle refTarg);
#else
private:
	virtual void	SetReference			(int i, RefTargetHandle refTarg);
public:
#endif

#if MAX_VERSION_MAJOR < 17	//Max 2015
	RefResult		NotifyRefChanged		(Interval changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message);
#else
	RefResult		NotifyRefChanged		(const Interval& changeInt, RefTargetHandle hTarget, PartID& partID, RefMessage message, BOOL propagate);
#endif

	// MtlBase ////////////////////////////////////////////////////////////////////////////////////

	ULONG			LocalRequirements		(int subMtlNum);
	void			LocalMappingsRequired	(int subMtlNum, BitArray& mapreq, BitArray& bumpreq);

	void			Update					(TimeValue t, Interval& valid);
	void			Reset					();
	Interval		Validity				(TimeValue t);

	IOResult		Save					(ISave* isave);
	IOResult		Load					(ILoad* iload);

	ParamDlg*		CreateParamDlg			(HWND hwMtlEdit, IMtlParams* imp);

	// Texmap /////////////////////////////////////////////////////////////////////////////////////

	RGBA			EvalColor				(ShadeContext& sc);
	float			EvalMono				(ShadeContext& sc);
	Point3			EvalNormalPerturb		(ShadeContext& sc);

	// IInfoTexture ///////////////////////////////////////////////////////////////////////////////

	BaseInterface*	GetInterface			(Interface_ID id);

	int				GetInfoType				();
	void			SetInfoType				(int infoType);

	int				GetWrapMode				();
	void			SetWrapMode				(int wrapMode);

	int				GetCoordSys				();
	void			SetCoordSys				(int coordSys);

private:
	IParamBlock2*	m_pblock;

	// Cache of pblock values for use during rendering
	InfoType		m_infoType;
	WrapMode		m_wrapMode;
	CoordSys		m_coordSys;
	int				m_uvwChannel;
	int				m_dataChannel;
	bool			m_useFullCameraNormalRange;
};
