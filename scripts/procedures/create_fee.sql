CREATE OR ALTER PROCEDURE CreateFee
    @Name NVARCHAR(255),
    @Lower BIGINT,
    @Upper BIGINT,
    @PerArea INT,
    @PerMotorbike INT,
    @PerCar INT,
    @Deadline DATE,
    @Description NVARCHAR(max),
    @Flags TINYINT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Id BIGINT
    EXECUTE GenerateId @Id = @Id OUTPUT

    INSERT INTO fees (
        id,
        name,
        lower,
        upper,
        per_area,
        per_motorbike,
        per_car,
        deadline,
        description,
        flags
    )
    OUTPUT INSERTED.*
    VALUES (
        @Id,
        @Name,
        @Lower,
        @Upper,
        @PerArea,
        @PerMotorbike,
        @PerCar,
        @Deadline,
        @Description,
        @Flags
    )
END
