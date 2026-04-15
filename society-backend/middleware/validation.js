const { ZodSchema, ZodError } = require("zod");
const { logger } = require("../src/shared/Logger");

/**
 * Higher-order middleware to validate request body using a Zod schema.
 * Rejects illegal payloads and returns structured error responses.
 */
const validate = (schema) => (req, res, next) => {
  try {
    // Parse and validate the request body
    // result.data will contain the stripped/cleaned object
    req.body = schema.parse(req.body);
    next();
  } catch (err) {
    if (err instanceof ZodError) {
      const errorDetails = err.errors.map((e) => ({
        field: e.path.join("."),
        message: e.message,
      }));

      logger.warn(
        { 
          path: req.path, 
          method: req.method, 
          errors: errorDetails 
        }, 
        "SEC-WARN: Input Validation Failed"
      );

      return res.status(400).json({
        error: "Validation failed",
        details: errorDetails,
      });
    }

    // Pass unexpected errors to the global handler
    next(err);
  }
};

module.exports = { validate };
