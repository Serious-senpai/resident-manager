CREATE OR ALTER PROCEDURE ApproveRegistrationRequests
    @Id BIGINTARRAY READONLY
AS
BEGIN
    SET NOCOUNT ON

    UPDATE accounts
    SET approved = 1
    WHERE id IN (
        SELECT value FROM @Id
    ) AND approved = 0
END
