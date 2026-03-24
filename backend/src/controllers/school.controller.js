import {
  createSchool,
  getAllSchools,
  getSchoolById,
  updateSchool,
  deleteSchool
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

// ✅ Update
export async function update(req, res) {
  try {
    const school = await updateSchool(
      req.params.id,
      req.body,
      req.user.id
    );

    res.json({
      message: "School updated successfully",
      school,
    });
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}

// ✅ Delete
export async function remove(req, res) {
  try {
    const result = await deleteSchool(req.params.id, req.user.id);

    res.json(result);
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}