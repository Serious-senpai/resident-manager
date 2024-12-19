-- Some params are required for substitution:
DECLARE
    @DefaultAdminUsername NVARCHAR(255) = ?,
    @DefaultAdminHashedPassword NVARCHAR(255) = ?,
    @Epoch DATETIME2 = ?

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config' AND type = 'U')
BEGIN
    CREATE TABLE config (
        name NVARCHAR(255) PRIMARY KEY,
        value NVARCHAR(max) NOT NULL
    )
    INSERT INTO config VALUES
        ('admin_username', @DefaultAdminUsername),
        ('admin_hashed_password', @DefaultAdminHashedPassword)
END

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config_bigint' AND type = 'U')
BEGIN
    CREATE TABLE config_bigint (
        name NVARCHAR(255) PRIMARY KEY,
        value BIGINT NOT NULL
    )
    INSERT INTO config_bigint VALUES ('id_counter', 0)
END

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config_datetime2' AND type = 'U')
BEGIN
    CREATE TABLE config_datetime2 (
        name NVARCHAR(255) PRIMARY KEY,
        value DATETIME2 NOT NULL
    )
    INSERT INTO config_datetime2 VALUES ('epoch', @Epoch)
END

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'rooms' AND type = 'U')
    CREATE TABLE rooms (
        room SMALLINT PRIMARY KEY,
        area INT NOT NULL, -- area = 100 * [area in square meters]
        motorbike TINYINT NOT NULL,
        car TINYINT NOT NULL
    )

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'accounts' AND type = 'U')
    CREATE TABLE accounts (
        id BIGINT PRIMARY KEY,
        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS NOT NULL,
        room SMALLINT NOT NULL,
        birthday DATE,
        phone NVARCHAR(15),
        email NVARCHAR(255),
        username NVARCHAR(255) UNIQUE NOT NULL,
        hashed_password NVARCHAR(255) NOT NULL,
        approved BIT NOT NULL
        -- CONSTRAINT FK_accounts_rooms FOREIGN KEY (room) REFERENCES rooms(room) -- room records are not always available
    )

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'fee' AND type = 'U')
    CREATE TABLE fee (
        id BIGINT PRIMARY KEY,
        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS NOT NULL,
        lower BIGINT NOT NULL, -- lower = 100 * [amount in VND]
        upper BIGINT NOT NULL, -- upper = 100 * [amount in VND]
        per_area INT NOT NULL, -- per_area = 100 * [amount in VND]
        per_motorbike INT NOT NULL, -- per_motorbike = 100 * [amount in VND]
        per_car INT NOT NULL, -- per_car = 100 * [amount in VND]
        deadline DATE NOT NULL,
        description NVARCHAR(max) COLLATE Vietnamese_100_CS_AS_KS_WS,
        flags TINYINT NOT NULL,
        CONSTRAINT CHECK_fee CHECK (lower <= upper)
    )

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'payments' AND type = 'U')
    CREATE TABLE payments (
        id BIGINT PRIMARY KEY,
        room SMALLINT NOT NULL,
        amount BIGINT NOT NULL, -- amount = 100 * [amount in VND]
        fee_id BIGINT NOT NULL,
        CONSTRAINT FK_payments_rooms FOREIGN KEY (room) REFERENCES rooms(room),
        CONSTRAINT FK_payments_fee FOREIGN KEY (fee_id) REFERENCES fee(id),
        CONSTRAINT UQ_payments_room_fee_id UNIQUE (room, fee_id)
    )

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'BIGINTARRAY')
    CREATE TYPE BIGINTARRAY AS TABLE (value BIGINT NOT NULL)
