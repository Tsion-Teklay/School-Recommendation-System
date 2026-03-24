import {
  createSchool,
  getAllSchools,
  getSchoolById,
} from "../services/school.service.js";

// ✅ Create
export async function create(req, res) {
  try {
    const school = await createSchool(req.body, req.user.id);

    res.status(201).json({
      message: "School created successfully",
      school,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get All (PUBLIC)
export async function getAll(req, res) {
  try {
    const schools = await getAllSchools();

    res.json({
      message: "Schools fetched successfully",
      data: schools,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// ✅ Get One
export async function getOne(req, res) {
  try {
    const school = await getSchoolById(req.params.id);

    res.json({
      message: "School fetched successfully",
      school,
    });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
}