CREATE OR ALTER PROCEDURE RejectRegistrationRequests
    @Id BIGINTARRAY READONLY
AS
BEGIN
    SET NOCOUNT ON

    DELETE FROM accounts
    WHERE id IN (
        SELECT value FROM @Id
    ) AND approved = 0
END
