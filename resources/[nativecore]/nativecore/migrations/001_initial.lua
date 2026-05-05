--[[
    NativeCore — Initial Database Migration
    Creates the core tables: nc_users and nc_identifiers.
]]

return {
    version = '001',
    name = 'initial',
    up = function(db)
        db.Execute([[
            CREATE TABLE IF NOT EXISTS nc_users (
                uuid        VARCHAR(36) PRIMARY KEY,
                name        VARCHAR(50) DEFAULT 'Unknown',
                `group`     VARCHAR(20) DEFAULT 'user',
                position    VARCHAR(150) DEFAULT '{"x":-269.4,"y":-955.3,"z":31.2,"heading":205.0}',
                metadata    JSON DEFAULT ('{}'),
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                last_seen   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db.Execute([[
            CREATE TABLE IF NOT EXISTS nc_identifiers (
                id          INT AUTO_INCREMENT PRIMARY KEY,
                uuid        VARCHAR(36) NOT NULL,
                type        VARCHAR(20) NOT NULL,
                value       VARCHAR(100) NOT NULL,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY uq_identifier (type, value),
                FOREIGN KEY (uuid) REFERENCES nc_users(uuid) ON DELETE CASCADE,
                INDEX idx_uuid (uuid)
            )
        ]])
    end,
}
