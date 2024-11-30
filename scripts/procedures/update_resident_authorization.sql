CREATE OR ALTER PROCEDURE UpdateResidentAuthorization
    @Id BIGINT,
    @Username NVARCHAR(255),
    @HashedPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION

        IF EXISTS (SELECT 1 FROM accounts WHERE id != @Id AND username = @Username)
            SELECT * FROM accounts WHERE 1 = 0

        ELSE
            UPDATE accounts
            SET
                username = @Username,
                hashed_password = @HashedPassword
            OUTPUT INSERTED.*
            WHERE id = @Id AND approved = 1

    COMMIT TRANSACTION
END
