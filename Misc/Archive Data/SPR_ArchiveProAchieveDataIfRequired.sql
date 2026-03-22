CREATE PROCEDURE [dbo].[SPR_ArchiveProAchieveDataIfRequired]
	@NameOfTableCreated NVARCHAR(50) OUTPUT,
	@NumRowsInserted INT OUTPUT, 
	@ErrorCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ILRReturnDetails VARCHAR(50)
	DECLARE @SQL VARCHAR(MAX)

	SELECT
		@ILRReturnDetails = REPLACE ( ILR.AcademicYear, '/', '' ) + '_' + FORMAT ( ILR.ReturnNo, 'R#00' )
	FROM ILRReturnDates ILR
	WHERE
		CAST ( ILR.ReturnDate AS DATE ) >= DATEADD(wk, 0, DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 0) ) -- Last weeks (if run on Mon change first 1 to 0)
		AND CAST ( ILR.ReturnDate AS DATE ) <= DATEADD(wk, 0, DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 4) ) -- Last weeks (if run on Mon change first 1 to 0)

	IF LEN ( @ILRReturnDetails ) > 0
	BEGIN
		--Create archived table
		SET @SQL = '
			SELECT *
			INTO ProAchieveLearnerData_' + @ILRReturnDetails + '
			FROM ProAchieveLearnerData'

		EXEC(@SQL)
		
		SET @NumRowsInserted = @@ROWCOUNT
		SET @NameOfTableCreated = N'ProAchieveLearnerData_' + @ILRReturnDetails
		
		--Add clustered index to archived table
		SET @SQL = '
			CREATE CLUSTERED INDEX CI_ProAchieveLearnerData_' + @ILRReturnDetails + ' ON ProAchieveLearnerData_' + @ILRReturnDetails + ' 
			(EndYear, SummaryType, ProviderID, DivisionCode, SubDivisionCode, CostCentreCode)'

		EXEC(@SQL)
	END

	SET @ErrorCode = @@ERROR
END