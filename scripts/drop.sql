IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'payments' AND type = 'U')
    DROP TABLE payments

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'fee' AND type = 'U')
    DROP TABLE fee

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'accounts' AND type = 'U')
    DROP TABLE accounts

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'rooms' AND type = 'U')
    DROP TABLE rooms

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config_datetime2' AND type = 'U')
    DROP TABLE config_datetime2

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config_bigint' AND type = 'U')
    DROP TABLE config_bigint

GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'config' AND type = 'U')
    DROP TABLE config

GO

DROP TYPE IF EXISTS BIGINTARRAY

GO
