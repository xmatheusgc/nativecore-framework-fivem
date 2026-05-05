return {
    -- Automatically run tests on server startup
    AutoRun = true,

    -- Delay (in ms) before auto-running tests (allows other scripts to register)
    AutoRunDelay = 5000,

    -- Optional filter for auto-run (e.g., 'core' to only run core tests)
    AutoRunFilter = '',

    -- Stop the server if any core test fails (for CI/CD environments)
    ExitOnError = false,
}
