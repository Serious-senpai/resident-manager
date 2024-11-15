IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'config' AND type = 'U')
    DROP TABLE config

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'rooms' AND type = 'U')
    DROP TABLE rooms

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'accounts' AND type = 'U')
    DROP TABLE accounts

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'fee' AND type = 'U')
    DROP TABLE fee

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'payments' AND type = 'U')
    DROP TABLE payments
