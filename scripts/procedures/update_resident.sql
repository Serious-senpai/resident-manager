CREATE OR ALTER PROCEDURE UpdateResident
    @Id BIGINT,
    @Name NVARCHAR(255),
    @Room SMALLINT,
    @Birthday DATE,
    @Phone NVARCHAR(15),
    @Email NVARCHAR(255)
AS
    SET NOCOUNT ON
    UPDATE accounts
    SET
        name = @Name,
        room = @Room,
        birthday = @Birthday,
        phone = @Phone,
        email = @Email
    OUTPUT INSERTED.*
    WHERE id = @Id AND approved = 1
