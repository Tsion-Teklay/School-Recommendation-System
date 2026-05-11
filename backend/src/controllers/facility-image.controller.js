import { asyncHandler } from "../middlewares/async.middleware.js";
import { relativeUrl } from "../config/uploads.js";
import { ValidationError } from "../utils/errors.js";
import {
  addFacilityImage,
  deleteFacilityImage,
  listFacilityImages,
} from "../services/facility-image.service.js";

export const list = asyncHandler(async (req, res) => {
  const images = await listFacilityImages(req.params.id);
  res.json({ images });
});

export const upload = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ValidationError("Missing image file under field 'image'");
  }
  const image = await addFacilityImage({
    schoolId: req.params.id,
    imageUrl: relativeUrl(req.file),
    userId: req.user.id,
  });
  res.status(201).json({
    message: "Facility image uploaded successfully",
    image,
  });
});

export const remove = asyncHandler(async (req, res) => {
  await deleteFacilityImage({
    schoolId: req.params.id,
    imageId: req.params.imgId,
    userId: req.user.id,
  });
  res.json({ message: "Facility image deleted successfully" });
});
