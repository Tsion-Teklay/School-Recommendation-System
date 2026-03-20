export function createTestResource(req, res) {
  res.json({
    message: "Resource created successfully",
    user: req.user, // shows decoded JWT
  });
}

export function getTestResources(req, res) {
  res.json({
    message: "List of resources",
    user: req.user,
    data: [
      { id: 1, name: "School A" },
      { id: 2, name: "School B" },
    ],
  });
}