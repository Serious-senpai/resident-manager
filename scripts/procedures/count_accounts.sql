CREATE OR ALTER PROCEDURE CountAccounts
    @CreatedAfter DATETIME2,
    @CreatedBefore DATETIME2,
    @Name NVARCHAR(255),
    @Room SMALLINT,
    @Username NVARCHAR(255),
    @Approved BIT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @FromId BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedAfter) << 16
    DECLARE @ToId BIGINT = (DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedBefore) << 16) | 0xFFFF

    SELECT COUNT(1) FROM accounts
    WHERE id >= @FromId AND id <= @ToId AND (
        @Name IS NULL
        OR CHARINDEX(@Name, name) > 0
    ) AND (
        @Room IS NULL
        OR room = @Room
    ) AND (
        @Username IS NULL
        OR CHARINDEX(@Username, username) > 0
    ) AND approved = @Approved
END
