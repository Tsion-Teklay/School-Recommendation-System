import { registerUser, loginUser } from "../services/auth.service.js";

export async function register(req, res) {
  try {
    const user = await registerUser(req.body);

    res.status(201).json({
      message: "User registered successfully",
      user,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

export async function login(req, res) {
  try {
    const { token, user } = await loginUser(req.body);

    res.json({
      message: "Login successful",
      token,
      user,
    });
  } catch (err) {
    res.status(401).json({ error: err.message });
  }
}