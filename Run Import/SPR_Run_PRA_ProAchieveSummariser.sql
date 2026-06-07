CREATE OR ALTER PROCEDURE dbo.SPR_Run_PRA_ProAchieveSummariser
	@AcademicYear NVARCHAR(5),
	@Mode NCHAR(1)
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON;

	DECLARE @ProviderID INT = 10005979 --Provider Ref of the college
	DECLARE @ProviderRef NVARCHAR(50) = 'HSDC' --Reference to save into table in case title too long for charts etc.
	--DECLARE @AcademicYear NVARCHAR(5) = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')

	--SET @AcademicYear = '25/26' --Override
	--DECLARE @Mode CHAR(1) = 'I' --I=Insert new yearly ProAchieve data leaving data for other years, R=Replace table


	DECLARE @ProGeneralDatabaseLocation NVARCHAR(200) = 'ProGeneral.dbo.' --Database/Linked Server location
	DECLARE @ProAchieveDatabaseLocation NVARCHAR(200) = 'ProAchieve.dbo.' --Database/Linked Server location
	DECLARE @OutputTableLocation NVARCHAR(200) = 'ProAchieveSummariser.dbo.' --Location where the resulting ProAchieve Summary Data table will be created

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
END