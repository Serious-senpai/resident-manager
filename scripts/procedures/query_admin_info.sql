CREATE OR ALTER PROCEDURE QueryAdminInfo
AS
BEGIN
    SET NOCOUNT ON

    SELECT (
        SELECT value FROM config WHERE name = 'admin_username'
    ), (
        SELECT value FROM config WHERE name = 'admin_hashed_password'
    )
END
