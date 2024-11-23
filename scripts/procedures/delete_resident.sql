CREATE OR ALTER PROCEDURE DeleteResidents
    @Id BIGINTARRAY READONLY
AS
    DELETE FROM accounts
    WHERE id IN (
        SELECT value FROM @Id
    ) AND approved = 1
