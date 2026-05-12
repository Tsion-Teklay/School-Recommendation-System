/**
 * Wraps an async route handler so that any thrown error is forwarded to
 * Express's error pipeline (i.e. the global error middleware). Removes the
 * need for try/catch in every controller.
 *
 *   router.get("/", asyncHandler(async (req, res) => { ... }));
 */
function asyncHandler(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

export default asyncHandler;
