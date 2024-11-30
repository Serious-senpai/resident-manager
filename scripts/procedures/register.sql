CREATE OR ALTER PROCEDURE Register
    @Name NVARCHAR(255),
    @Room SMALLINT,
    @Birthday DATETIME,
    @Phone NVARCHAR(15),
    @Email NVARCHAR(255),
    @Username NVARCHAR(255),
    @HashedPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Id BIGINT
    EXECUTE GenerateId @Id = @Id OUTPUT

    BEGIN TRANSACTION
        IF EXISTS (SELECT 1 FROM accounts WHERE username = @Username)
            SELECT * FROM accounts WHERE 1 = 0

        ELSE
            INSERT INTO accounts (id, name, room, birthday, phone, email, username, hashed_password, approved)
            OUTPUT INSERTED.*
            VALUES (@Id, @Name, @Room, @Birthday, @Phone, @Email, @Username, @HashedPassword, 0)

    COMMIT TRANSACTION
END
