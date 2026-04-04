DECLARE @ProviderID INT = 10001475 --Provider Ref of the college
DECLARE @ProviderRef NVARCHAR(50) = 'EPNE' --Reference to save into table in case title too long for charts etc.
DECLARE @AcademicYear NVARCHAR(5) = ''

SET @AcademicYear = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')
--SET @AcademicYear = '25/26' --Override
DECLARE @Mode CHAR(1) = 'I' --I=Insert new yearly ProAchieve data leaving data for other years, R=Replace table
DECLARE @ProGeneralDatabaseLocation NVARCHAR(200) = 'besql05.ProGeneral.dbo.' --Database/Linked Server location
DECLARE @ProAchieveDatabaseLocation NVARCHAR(200) = 'besql05.ProAchieve.dbo.' --Database/Linked Server location
DECLARE @OutputTableLocation NVARCHAR(200) = 'EPNE.dbo.' --Location where the resulting ProAchieve Summary Data table will be created
DECLARE @UserDefinedTrueValue NVARCHAR(50) = 'Y' --The value that indicates ALS is provided - e.g. Y/True
DECLARE @ALSStudentUserDefinedField INT = 1 --UDF where ALS is imported as Y/N
DECLARE @LookedAfterStudentUserDefinedField INT = 3
DECLARE @CareLeaverStudentUserDefinedField INT = 2
DECLARE @YoungCarerStudentUserDefinedField INT = 4
DECLARE @YoungParentStudentUserDefinedField INT = 5
DECLARE @GroupCodeEnrolmentUserDefinedField INT = 1 --UDF where the course group code is stored

DECLARE @NumRowsChanged INT
DECLARE @ErrorCode INT

DECLARE @SQLString NVARCHAR(MAX);
DECLARE @SQLParams NVARCHAR(MAX);

DECLARE @Message VARCHAR(MAX);

SET @SQLString = N'
    EXEC SPR_PRA_GenerateProAchieveSummaryData
        @ProviderID,
		@ProviderRef,
		@AcademicYear,
        @Mode,
        @ProGeneralDatabaseLocation,
        @ProAchieveDatabaseLocation,
        @OutputTableLocation,
		@UserDefinedTrueValue,
		@ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged, 
	    @ErrorCode';

SET @SQLParams = 
        N'@ProviderID INT,
		@ProviderRef NVARCHAR(50),
		@AcademicYear NVARCHAR(5),
        @Mode CHAR(1),
        @ProGeneralDatabaseLocation NVARCHAR(200),
        @ProAchieveDatabaseLocation NVARCHAR(200),
        @OutputTableLocation NVARCHAR(200),
		@UserDefinedTrueValue NVARCHAR(50),
		@ALSStudentUserDefinedField INT,
		@LookedAfterStudentUserDefinedField INT,
		@CareLeaverStudentUserDefinedField INT,
		@YoungCarerStudentUserDefinedField INT,
		@YoungParentStudentUserDefinedField INT,
		@GroupCodeEnrolmentUserDefinedField INT,
        @NumRowsChanged INT OUTPUT, 
	    @ErrorCode INT OUTPUT';
    
EXECUTE sp_executesql 
    @SQLString, 
    @SQLParams, 
    @ProviderID = @ProviderID,
	@ProviderRef = @ProviderRef,
	@AcademicYear = @AcademicYear, 
    @Mode = @Mode,
    @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
    @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
    @OutputTableLocation = @OutputTableLocation,
	@UserDefinedTrueValue = @UserDefinedTrueValue,
	@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
	@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
	@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
	@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
	@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
	@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
    @NumRowsChanged = @NumRowsChanged OUTPUT,
	@ErrorCode = @ErrorCode OUTPUT

IF(@ErrorCode > 0)
	BEGIN
		SET @Message = N'Errors Occurred - Code: ' + CAST ( @ErrorCode AS NVARCHAR(10) )
		RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;
	END
ELSE
	BEGIN
		SET @Message = N'Records Inserted: ' + CAST ( @NumRowsChanged AS NVARCHAR(10) )
		RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;
	END