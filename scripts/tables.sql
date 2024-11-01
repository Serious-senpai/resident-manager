-- Some params are required for substitution:
DECLARE
    @DefaultAdminUsername NVARCHAR(255) = ?,
    @DefaultAdminHashedPassword NVARCHAR(255) = ?

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'residents' AND type = 'U')
    CREATE TABLE residents (
        resident_id BIGINT PRIMARY KEY,
        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
        room SMALLINT NOT NULL,
        birthday DATETIME,
        phone NVARCHAR(15),
        email NVARCHAR(255),
        username NVARCHAR(255) UNIQUE NOT NULL,
        hashed_password NVARCHAR(255) NOT NULL
    )

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'register_queue' AND type = 'U')
    CREATE TABLE register_queue (
        request_id BIGINT PRIMARY KEY,
        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
        room SMALLINT NOT NULL,
        birthday DATETIME,
        phone NVARCHAR(15),
        email NVARCHAR(255),
        username NVARCHAR(255) UNIQUE NOT NULL,
        hashed_password NVARCHAR(255) NOT NULL
    )

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'config' AND type = 'U')
BEGIN
    CREATE TABLE config (
        name NVARCHAR(255) PRIMARY KEY,
        value NVARCHAR(255) NOT NULL
    )
    INSERT INTO config VALUES ('admin_username', @DefaultAdminUsername)
    INSERT INTO config VALUES ('admin_hashed_password', @DefaultAdminHashedPassword)
END

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'fee' AND type = 'U')
    CREATE TABLE fee (
        fee_id BIGINT PRIMARY KEY,
        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
        lower INT NOT NULL, -- lower = 100 * [amount in VND]
        upper INT NOT NULL, -- upper = 100 * [amount in VND]
        date DATETIME NOT NULL,
        description NVARCHAR(max) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8,
        flags TINYINT NOT NULL,
        CHECK (lower <= upper),
    )

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'rooms' AND type = 'U')
    CREATE TABLE rooms (
        room SMALLINT PRIMARY KEY,
        area INT NOT NULL, -- area = 100 * [area in square meters]
        motorbike TINYINT NOT NULL,
        car TINYINT NOT NULL,
    )

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'payments' AND type = 'U')
    CREATE TABLE payments (
        payment_id BIGINT PRIMARY KEY,
        room SMALLINT NOT NULL,
        amount INT NOT NULL, -- amount = 100 * [amount in VND]
    )
