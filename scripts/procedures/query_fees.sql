CREATE OR ALTER PROCEDURE QueryFees
    @CreatedAfter DATETIME2,
    @CreatedBefore DATETIME2,
    @Name NVARCHAR(255),
    @OrderBy INT,
    @Offset INT,
    @FetchNext INT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @FromId BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedAfter) << 16
    DECLARE @ToId BIGINT = (DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedBefore) << 16) | 0xFFFF

    SELECT * FROM fee
    WHERE id >= @FromId AND id <= @ToId AND (
        @Name IS NULL
        OR CHARINDEX(@Name, name) > 0
    )
    ORDER BY
        CASE
            WHEN @OrderBy = 1 THEN id
        END ASC,
        CASE
            WHEN @OrderBy = 2 THEN name
        END ASC,
        CASE
            WHEN @OrderBy = 3 THEN lower
        END ASC,
        CASE
            WHEN @OrderBy = 4 THEN upper
        END ASC,
        CASE
            WHEN @OrderBy = 5 THEN per_area
        END ASC,
        CASE
            WHEN @OrderBy = 6 THEN per_motorbike
        END ASC,
        CASE
            WHEN @OrderBy = 7 THEN per_car
        END ASC,
        CASE
            WHEN @OrderBy = 8 THEN deadline
        END ASC,
        CASE
            WHEN @OrderBy = -1 THEN id
        END DESC,
        CASE
            WHEN @OrderBy = -2 THEN name
        END DESC,
        CASE
            WHEN @OrderBy = -3 THEN lower
        END DESC,
        CASE
            WHEN @OrderBy = -4 THEN upper
        END DESC,
        CASE
            WHEN @OrderBy = -5 THEN per_area
        END DESC,
        CASE
            WHEN @OrderBy = -6 THEN per_motorbike
        END DESC,
        CASE
            WHEN @OrderBy = -7 THEN per_car
        END DESC,
        CASE
            WHEN @OrderBy = -8 THEN deadline
        END DESC
        OFFSET @Offset ROWS
        FETCH NEXT @FetchNext ROWS ONLY
END
