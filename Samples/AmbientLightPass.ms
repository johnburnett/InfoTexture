---------------------------------------------------------------------------------------------------
-- Example script demonstrating post-process ambient lighting.
-- Set filenames below to files that actually exist, and then evaluate the script.
--
-- normalPassFilename should be an image rendered using InfoTexture's "Normal" mode in "World Space".
-- lightProbeFilename should be any image that would make a good reflection/skydome texture.

normalPassFilename = "c:/output/teapot_normal.tga"
lightProbeFilename = "c:/output/lake_panorama.tga"

---------------------------------------------------------------------------------------------------
-- Implementation details... nothing to see here.

fn GetFilteredPixel image x y =
(
	local ix = x as integer
	local iy = y as integer

	if (
		ix < 0 or
		iy < 0 or
		ix >= (image.width-2) or
		iy >= (image.height-2)
	) then (
		(GetPixels image [ix, iy] 1)[1]
	) else (
		local fx = x - ix
		local fy = y - iy
		local fxi = 1.0 - fx
		local fyi = 1.0 - fy

		(GetPixels image [ix  , iy  ] 1)[1] * fxi * fyi +
		(GetPixels image [ix+1, iy  ] 1)[1] * fx  * fyi +
		(GetPixels image [ix  , iy+1] 1)[1] * fxi *  fy +
		(GetPixels image [ix+1, iy+1] 1)[1] * fx  *  fy
	)
)

fn GetAmbientLightPass lightProbe normalPass =
(
	try (
		local output = Bitmap normalPass.width normalPass.height

		local p3one = [1.0, 1.0, 1.0]
		local inv127 = 1.0 / 127.5
		local inv180 = 1.0 / 180.0
		local inv720 = 1.0 / 720.0

		for iy in 0 to (output.height-1) do
		(
			local row = GetPixels normalPass [0, iy] output.width

			for ix in 1 to row.count do
			(
				if (row[ix].a < 255) then
				(
					row[ix] = black
				) else (
					local normal = ((row[ix] as Point3) * inv127) - p3one

					local sampleX = ((atan2 normal.x normal.y) * inv720 + 0.5) * (lightProbe.width-1)
					local sampleY = (acos normal.z) * inv180 * (lightProbe.height-1)

					row[ix] = GetFilteredPixel lightProbe sampleX sampleY
					if (row[ix] == undefined) then row[ix] = green
				)
			)

			SetPixels output [0, iy] row
		)

		output
	) catch (
		undefined
	)
)

(
	gc()

	local normalPass = OpenBitmap normalPassFilename
	if (normalPass == undefined) then throw "Must specify an image containing a normal pass rendering."

	local lightProbe = OpenBitmap lightProbeFilename
	if (lightProbe == undefined) then throw "Must specify an image to use as a light probe."

	local ambientPass = GetAmbientLightPass lightProbe normalPass
	if (ambientPass == undefined) then throw "Unhandled error in GetAmbientLightPass()."

	Display normalPass
	Display lightProbe
	Display ambientPass
)
