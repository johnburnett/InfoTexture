---------------------------------------------------------------------------------------------------
-- Example script demonstrating fast hit-testing based on rendered images.
--
-- Simply run the script to get a timing comparison between InfoTexture hit-testing and IntersectRayEx
-- hit-testing.  On 3Ghz P4, the default test timings are:
--	InfoTexture style: 0.016 seconds
--	IntersectRayEx style: 16.109 seconds

(
	MessageBox "This will take a while.\n\nTest will be done when the pictures go away." title:"MONKEY"

	---------------------------------------------
	-- First, start fresh and create a test scene of teapots.
	-- All teapots share a common self-illuminated material with an InfoTexture.

	ResetMaxFile #noPrompt

	local infoTex = InfoTexture()
	local mat = StandardMaterial selfIllumAmount:100 specularLevel:0 diffuseMap:infoTex

	---------------------------------------------
	-- Initially just test a single teapot.  Set singleTeapot to false to test multiple teapots.
	-- However, if testing multiple teapots, the IntersectRayEx loop below must be modified to
	-- test EACH teapot in succession, since IntersectRayEx only works on one node at a time.
	-- The InfoTexture hit-test method implicitly hit-tests all nodes at once.

	local singleTeapot = true
	if (singleTeapot) then
	(
		local sourceTeapot = Teapot pos:[0,0,-30] radius:50.0 segments:50 boxmode:true material:mat
		ConvertToMesh sourceTeapot
	) else (
		local sourceTeapot = Teapot pos:[0,0,0] radius:10.0 segments:10 boxmode:true material:mat
		ConvertToMesh sourceTeapot

		for ii in 1 to 100 do
		(
			local dup = Instance sourceTeapot
			dup.rotation = Random (Quat 0 0 -1 1) (Quat 0 0 1 1)
			dup.pos = Random [-50,-50,-50] [50,50,50]
		)

		Delete sourceTeapot
	)

	---------------------------------------------
	-- Setup scene and renderer

	local cam = TargetCamera fov:36 nearclip:1 farclip:1000 mpassEnabled:off pos:[-152.343,-123.365,102.046] target:(TargetObject pos:[0,0,0])
	local dummyLight = OmniLight enabled:false

	renderer = #draft
	renderers.draft = Default_Scanline_Renderer()
	renderers.draft.antiAliasing =
		renderers.draft.shadows =
		renderers.draft.autoReflect =
		renderers.draft.forceWireframe =
		renderers.draft.objectMotionBlur =
		renderers.draft.imageMotionBlur = false

	---------------------------------------------
	-- Render our passes.  Normally you'd have vfb:false so the renders aren't actually seen.

	local passRes = [1000,1000]

	infoTex.infoType = 0 -- Face Index mode.  This render also includes the node g-buffer channel (to avoid a third render).
	local faceIndexPass = Render camera:cam outputSize:passRes vfb:true renderType:#normal channels:#(#node)

	infoTex.infoType = 1 -- Barycentric Coords mode
	local baryCoordsPass = Render camera:cam outputSize:passRes vfb:true renderType:#normal

	---------------------------------------------
	-- Collect some random points in screen space to use for a speed test.

	local screenHitTestPoints = for ii in 1 to 500 collect Random [0.0, 0.0] [1.0, 1.0]

	---------------------------------------------
	-- Transform the same hit points into world space rays to make the IntersectRayEx test faster/more fair.

	viewport.SetCamera cam
	if (viewport.GetCamera() != cam) then throw "Can't set camera to active viewport."
	local viewSize = GetViewSize()
	ForceCompleteRedraw()
	local worldHitTestPoints = for pnt in screenHitTestPoints collect MapScreenToWorldRay [viewSize.x*pnt.x, viewSize.y*pnt.y]

	--for r in worldHitTestPoints do point pos:r.pos dir:r.dir cross:false centermarker:false axistripod:true

	---------------------------------------------
	-- Define a function that hittests using InfoTexture render passes.
	--
	-- hitTestPoint: a screen space point to hittest, in the range [0,0] to [1,1]
	-- faceIndexPass: an InfoTexture "Face Index" rendering.  Also assumed to contain #node g-buffer channel.
	-- baryCoordsPass: an InfoTexture "Bary Coords" rendering.  Assumed to be the same resolution as faceIndexPass.
	--
	-- returns: undefined if nothing hit, or an array in the form #(node, faceIndex, baryCoords)

	fn InfoTextureHitTest hitTestPoint faceIndexPass baryCoordsPass =
	(
		local pixel = [	(hitTestPoint.x * (faceIndexPass.width-1)) as integer,
						(hitTestPoint.y * (faceIndexPass.height-1)) as integer]

		local faceIndexColor = (GetPixels faceIndexPass pixel 1)[1]
		if (faceIndexColor.a < 255) then return undefined -- nothing was hit

		local faceIndex = faceIndexColor.r + (bit.Shift faceIndexColor.g 8) + (bit.Shift faceIndexColor.b 16) + 1
		local baryCoordColor = (GetPixels baryCoordsPass pixel 1)[1]
		local baryCoord = Point3 (baryCoordColor.r/255.0) (baryCoordColor.g/255.0) (baryCoordColor.b/255.0)
		local node = GetChannel faceIndexPass pixel #node

		#(node, faceIndex, baryCoord)
	)

	---------------------------------------------
	-- Time away!

	format "Timing % hit-tests:\n" screenHitTestPoints.count
	local startTime, endTime

	startTime = TimeStamp()
	for hitTestPoint in screenHitTestPoints do InfoTextureHitTest hitTestPoint faceIndexPass baryCoordsPass
	endTime = TimeStamp()
	format "InfoTexture style: % seconds\n" ((endTime - startTime) / 1000.0)

	startTime = TimeStamp()
	for hitTestPoint in worldHitTestPoints do IntersectRayEx objects[1] hitTestPoint
	endTime = TimeStamp()
	format "IntersectRayEx style: % seconds\n" ((endTime - startTime) / 1000.0)
)

gc()
