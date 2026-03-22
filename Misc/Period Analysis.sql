
DECLARE @AcademicYear VARCHAR(5) = '20/21'
DECLARE @SummaryType VARCHAR(20) = 'Overall'
DECLARE @SummaryMeasure VARCHAR(20) = 'RulesApplied'
DECLARE @College VARCHAR(20) = 'ALL'
DECLARE @Faculty VARCHAR(20) = 'ALL'
DECLARE @Team VARCHAR(20) = 'ALL'


DECLARE @OneYearAgo VARCHAR(5) = CAST ( CAST ( LEFT ( @AcademicYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + '/' + CAST ( CAST ( RIGHT ( @AcademicYear, 2 ) AS INT ) - 1 AS VARCHAR(2) )
DECLARE @TwoYearsAgo VARCHAR(5) = CAST ( CAST ( LEFT ( @AcademicYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + '/' + CAST ( CAST ( RIGHT ( @AcademicYear, 2 ) AS INT ) - 2 AS VARCHAR(2) )

SELECT
	AcademicYear = PA.StartYear,
	CampusCode = PA.CampusID,
	CampusName = 
		CASE
			WHEN PA.CampusID = 'M0147501' THEN 'Sunderland'
			WHEN PA.CampusID = 'C0147502' THEN 'Northumberland'
			WHEN PA.CampusID = 'C0741502' THEN 'Hartlepool'
			ELSE 'Unknown'
		END,
	ProvisionType = 
		CASE
			WHEN PA.SubcontractorCode = '00000000' THEN 'Direct'
			ELSE 'Franchised'
		END,
	PA.StartPeriodID,
	PA.IsStart,
	PA.IsWdrInQualifyingPeriod,
	PA.IsWdrAfterQualifyingPeriod
FROM EPNE.dbo.PRA_ProAchieveSummaryData PA
WHERE
	PA.StartYear BETWEEN @TwoYearsAgo AND @AcademicYear
	AND PA.SummaryType = 'ER_' + @SummaryType + '_' + CASE WHEN @SummaryMeasure = 'RulesApplied' THEN 'AllAims' ELSE @SummaryMeasure END
	AND ( PA.CollegeCode IN ( @College ) OR 'ALL' IN ( @College ) )
	AND ( PA.FacCode IN ( @Faculty ) OR 'ALL' IN ( @Faculty ) )
	AND ( PA.TeamCode IN ( @Team ) OR 'ALL' IN ( @Team ) )
	AND PA.StartYear = @AcademicYear
	AND (
		PA.IsStart = 1
		OR PA.IsWdrInQualifyingPeriod = 1
	)