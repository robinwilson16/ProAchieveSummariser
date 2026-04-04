CREATE PROCEDURE [dbo].[SPR_SAR002_ProAchieveData]
	@EndYear NVARCHAR(5),
	@SummaryCourseType NVARCHAR(2),
	@SummaryType NVARCHAR(20),
	@SummaryMeasure NVARCHAR(20),
	@College NVARCHAR(50),
	@Fac NVARCHAR(50),
	@Team NVARCHAR(50),
	@SubcontractedProvision BIT,
	@DisplayHeadline BIT,
	@DisplayCollege BIT,
	@DisplayFaculty BIT,
	@DisplayTeam BIT,
	@CriteriaTitle NVARCHAR(255),
	@CriteriaOrder INT,
	@NatAvgAllAges NVARCHAR(50),
	@NatAvgAllAgesDesc NVARCHAR(50),
	@NatAvgAge NVARCHAR(50),
	@NatAvgAgeDesc NVARCHAR(50),
	@GroupBy NVARCHAR(255),
	@GroupByDesc NVARCHAR(255),
	@WhereClause NVARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @EndYear NVARCHAR(5) = '19/20'
	--DECLARE @SummaryCourseType NVARCHAR(2) = 'CL'
	--DECLARE @SummaryType NVARCHAR(20) = 'Overall'
	--DECLARE @SummaryMeasure NVARCHAR(20) = 'RulesApplied'
	--DECLARE @College NVARCHAR(50) = 'ALL'
	--DECLARE @Fac NVARCHAR(50) = 'ALL'
	--DECLARE @Team NVARCHAR(50) = 'ALL'
	--DECLARE @SubcontractedProvision BIT = 1
	--DECLARE @DisplayHeadline BIT = 1
	--DECLARE @DisplayCollege BIT = 1
	--DECLARE @DisplayFaculty BIT = 1
	--DECLARE @DisplayTeam BIT = 1

	--DECLARE @CriteriaTitle NVARCHAR(255) = NULL
	--DECLARE @CriteriaOrder INT = NULL
	--DECLARE @NatAvgAllAges NVARCHAR(50) = NULL
	--DECLARE @NatAvgAllAgesDesc NVARCHAR(50) = NULL
	--DECLARE @NatAvgAge NVARCHAR(50) = NULL
	--DECLARE @NatAvgAgeDesc NVARCHAR(50) = NULL
	--DECLARE @GroupBy NVARCHAR(255) = NULL
	--DECLARE @GroupByDesc NVARCHAR(255) = NULL
	--DECLARE @WhereClause NVARCHAR(255) = NULL

	--SET @CriteriaTitle = 'Headline'
	--SET @CriteriaOrder = 1
	--SET @NatAvgAllAges = 'Yr'
	--SET @NatAvgAllAgesDesc = 'Year'
	--SET @NatAvgAge = 'Age'
	--SET @NatAvgAgeDesc = 'Year + Age Group'
	--SET @GroupBy = 'CASE WHEN PA.EndYear > ''0'' THEN PA.EndYear ELSE PA.EndYear END'
	--SET @GroupByDesc = ''
	--SET @WhereClause = ''

	DECLARE @SQLString NVARCHAR(MAX);
	DECLARE @SQLParams NVARCHAR(MAX);

	SET @College = REPLACE ( @College, ' ', '' )
	SET @Fac = REPLACE ( @Fac, ' ', '' )
	SET @Team = REPLACE ( @Team, ' ', '' )

	SET @SQLString = 
        N'
		SELECT
			EndYear = @EndYear,
			EndYearLastYear =  CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ),
			EndYear2YearsAgo =  CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ),
			CriteriaTitle = PRA.CriteriaTitle,
			CriteriaOrder = PRA.CriteriaOrder,
			Criteria = PRA.GroupByFields,
			SortGroup = PRA.SortGroup,
			SortOrder = PRA.SortOrder,
			Title = PRA.Title,
			College = PRA.College,
			Faculty = PRA.Faculty,
			Team = PRA.Team,
			AgeGroup = PRA.AgeGroup,
			Leavers2YearsAgo = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) THEN PRA.Leavers ELSE NULL END ),
			Ret2YearsAgo = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END ),
			Ach2YearsAgo = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END ),
			Pass2YearsAgo = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) THEN PRA.PassedPer ELSE NULL END ),
			LeaversLastYear = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.Leavers ELSE NULL END ),
			RetLastYear = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END ),
			AchLastYear = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END ),
			PassLastYear = MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.PassedPer ELSE NULL END ),
			LeaversThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.Leavers ELSE NULL END ),
			RetThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ),
			AchThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ),
			PassThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.PassedPer ELSE NULL END ),
			RetNatRateThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatRetRate ELSE NULL END ),
			AchNatRateThisYear = MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatAchRate ELSE NULL END ),

			PassVarianceLastYear = 
				ROUND ( 
					MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
					- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END )
				, 3 ),
			PassVarianceNR = 
				ROUND ( 
					MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
					- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatRetRate ELSE NULL END )
				, 3 ),
			PassRAGRating = 
				CASE
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END )
						, 3 ) < 0
						AND
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatRetRate ELSE NULL END )
						, 3 ) < 0 THEN ''R''
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END )
						, 3 ) < 0
						OR
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatRetRate ELSE NULL END )
						, 3 ) < 0 THEN ''A''
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.RetainedPer ELSE NULL END )
						, 3 ) IS NULL
						AND
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.RetainedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatRetRate ELSE NULL END )
						, 3 ) IS NULL THEN ''-''
					ELSE ''G''
				END,

			AchVarianceLastYear = 
				ROUND ( 
					MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
					- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END )
				, 3 ),
			AchVarianceNR = 
				ROUND ( 
					MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
					- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatAchRate ELSE NULL END )
				, 3 ),
			AchRAGRating = 
				CASE
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END )
						, 3 ) < 0
						AND
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatAchRate ELSE NULL END )
						, 3 ) < 0 THEN ''R''
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END )
						, 3 ) < 0
						OR
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatAchRate ELSE NULL END )
						, 3 ) < 0 THEN ''A''
					WHEN 
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) THEN PRA.AchievedPer ELSE NULL END )
						, 3 ) IS NULL
						AND
						ROUND ( 
							MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.AchievedPer ELSE NULL END ) 
							- MIN ( CASE WHEN PRA.EndYear = @EndYear THEN PRA.NatAchRate ELSE NULL END )
						, 3 ) IS NULL THEN ''-''
					ELSE ''G''
				END,
			NatAvgAllAgesDesc = @NatAvgAllAgesDesc,
			NatAvgAgeDesc = @NatAvgAgeDesc,
			GroupByDesc = @GroupByDesc
		FROM (
	'

    SET @SQLString += 
		N'
			--Headline
			SELECT
				PA.EndYear,
				SortGroup = 1,
				SortOrder = 1,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''College Level'',
				College = NULL,
				Faculty = NULL,
				Team = NULL,
				AgeGroup = ''All Ages'',
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAllAges + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				--AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				--AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayHeadline = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				PA.NatRate_' + @NatAvgAllAges + '_AchPer
	'

    SET @SQLString += 
		N'
			UNION ALL
	
			SELECT
				EndYear = PA.EndYear,
				SortGroup = 1,
				SortOrder = 2,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''College Level'',
				College = NULL,
				Faculty = NULL,
				Team = NULL,
				AgeGroup = PA.AgeGroup,
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAge + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAge + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				--AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				--AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayHeadline = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.AgeGroup,
				PA.NatRate_' + @NatAvgAge + '_RetPer,
				PA.NatRate_' + @NatAvgAge + '_AchPer
	'

	SET @SQLString += 
		N'
			UNION ALL

			--College
			SELECT
				PA.EndYear,
				SortGroup = 2,
				SortOrder = 1,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''College Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = NULL,
				Team = NULL,
				AgeGroup = ''All Ages'',
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAllAges + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				--AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayCollege = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				PA.NatRate_' + @NatAvgAllAges + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName
	'

    SET @SQLString += 
		N'
			UNION ALL
	
			SELECT
				EndYear = PA.EndYear,
				SortGroup = 2,
				SortOrder = 2,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''College Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = NULL,
				Team = NULL,
				AgeGroup = PA.AgeGroup,
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAge + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAge + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				--AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayFaculty = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.AgeGroup,
				PA.NatRate_' + @NatAvgAge + '_RetPer,
				PA.NatRate_' + @NatAvgAge + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName
	'

    SET @SQLString += 
		N'
			UNION ALL

			--Faculty
			SELECT
				PA.EndYear,
				SortGroup = 3,
				SortOrder = 1,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''Faculty Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = PA.FacCode + '' - '' + PA.FacName,
				Team = NULL,
				AgeGroup = ''All Ages'',
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAllAges + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayFaculty = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				PA.NatRate_' + @NatAvgAllAges + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName,
				PA.FacCode + '' - '' + PA.FacName
	'

    SET @SQLString += 
		N'
			UNION ALL
	
			SELECT
				EndYear = PA.EndYear,
				SortGroup = 3,
				SortOrder = 2,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''Faculty Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = PA.FacCode + '' - '' + PA.FacName,
				Team = NULL,
				AgeGroup = PA.AgeGroup,
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAge + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAge + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				--AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayFaculty = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.AgeGroup,
				PA.NatRate_' + @NatAvgAge + '_RetPer,
				PA.NatRate_' + @NatAvgAge + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName,
				PA.FacCode + '' - '' + PA.FacName
	'

    SET @SQLString += 
		N'
			UNION ALL

			--Team
			SELECT
				PA.EndYear,
				SortGroup = 4,
				SortOrder = 1,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''Team Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = PA.FacCode + '' - '' + PA.FacName,
				Team = PA.TeamCode + '' - '' + PA.TeamName,
				AgeGroup = ''All Ages'',
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAllAges + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayTeam = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.NatRate_' + @NatAvgAllAges + '_RetPer,
				PA.NatRate_' + @NatAvgAllAges + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName,
				PA.FacCode + '' - '' + PA.FacName,
				PA.TeamCode + '' - '' + PA.TeamName
	'

    SET @SQLString += 
		N'
			UNION ALL
	
			SELECT
				EndYear = PA.EndYear,
				SortGroup = 4,
				SortOrder = 2,
				CriteriaTitle = @CriteriaTitle,
				CriteriaOrder = @CriteriaOrder,
				GroupByFields = ' + @GroupBy + ',
				Title = ''Team Level'',
				College = PA.CollegeCode + '' - '' + PA.CollegeName,
				Faculty = PA.FacCode + '' - '' + PA.FacName,
				Team = PA.TeamCode + '' - '' + PA.TeamName,
				AgeGroup = PA.AgeGroup,
				Leavers = SUM ( PA.IsLeaver ),
				Retained = SUM ( PA.IsRet ),
				RetainedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsComp ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				Completed = SUM ( PA.IsComp ),
				Achieved = SUM ( PA.IsAch ),
				AchievedPer = 
					CASE
						WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 3 )
					END,
				PassedPer = 
					CASE
						WHEN SUM ( PA.IsComp ) = 0 THEN 0
						ELSE ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsComp ) AS FLOAT ), 3 )
					END,
				NatRetRate = PA.NatRate_' + @NatAvgAge + '_RetPer,
				NatAchRate = PA.NatRate_' + @NatAvgAge + '_AchPer
			FROM PRA_ProAchieveSummaryData PA
			WHERE
				PA.EndYear BETWEEN 
					CAST ( CAST ( LEFT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + ''/'' + CAST ( CAST ( RIGHT ( @EndYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) 
					AND @EndYear
				AND PA.SummaryType = @SummaryCourseType + ''_'' + @SummaryType + ''_'' + @SummaryMeasure
				AND ( PA.CollegeCode IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @College, '','' ) ) )
				AND ( PA.FacCode IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Fac, '','' ) ) )
				AND ( PA.TeamCode IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) OR ''ALL'' IN ( SELECT Value FROM STRING_SPLIT ( @Team, '','' ) ) )
				AND
					CASE
						WHEN @SubcontractedProvision IS NULL THEN 1
						WHEN @SubcontractedProvision = ''1'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 0
								ELSE 1
							END
						WHEN @SubcontractedProvision = ''0'' THEN
							CASE
								WHEN PA.SubcontractorCode = ''00000000'' THEN 1
								ELSE 0
							END
						ELSE 0
					END = 1
				AND @DisplayTeam = 1
				' + COALESCE ( @WhereClause, '' ) + '
			GROUP BY
				PA.EndYear,
				' + @GroupBy + ',
				PA.AgeGroup,
				PA.NatRate_' + @NatAvgAge + '_RetPer,
				PA.NatRate_' + @NatAvgAge + '_AchPer,
				PA.CollegeCode + '' - '' + PA.CollegeName,
				PA.FacCode + '' - '' + PA.FacName,
				PA.TeamCode + '' - '' + PA.TeamName
		) PRA
		GROUP BY
			PRA.CriteriaTitle,
			PRA.CriteriaOrder,
			PRA.GroupByFields,
			PRA.SortGroup,
			PRA.SortOrder,
			PRA.Title,
			PRA.College,
			PRA.Faculty,
			PRA.Team,
			PRA.AgeGroup
		ORDER BY
			PRA.CriteriaOrder,
			PRA.SortGroup,
			PRA.College,
			PRA.Faculty,
			PRA.Team,
			PRA.SortOrder,
			PRA.AgeGroup,
			PRA.GroupByFields'

	--SELECT @SQLString AS [processing-instruction(x)] FOR XML PATH('')

	SET @SQLParams = 
        N'@EndYear NVARCHAR(5),
		@SummaryCourseType NVARCHAR(2),
		@SummaryType NVARCHAR(20),
		@SummaryMeasure NVARCHAR(20),
		@College NVARCHAR(50),
		@Fac NVARCHAR(50),
		@Team NVARCHAR(50),
		@SubcontractedProvision BIT,
		@DisplayHeadline BIT,
		@DisplayCollege BIT,
		@DisplayFaculty BIT,
		@DisplayTeam BIT,
		@CriteriaTitle NVARCHAR(255),
		@CriteriaOrder INT,
		@NatAvgAllAgesDesc NVARCHAR(50),
		@NatAvgAgeDesc NVARCHAR(50),
		@GroupByDesc NVARCHAR(255),
		@WhereClause NVARCHAR(255)';

    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@EndYear = @EndYear,
		@SummaryCourseType = @SummaryCourseType,
        @SummaryType = @SummaryType,
		@SummaryMeasure = @SummaryMeasure,
		@College = @College,
		@Fac = @Fac,
		@Team = @Team,
		@SubcontractedProvision = @SubcontractedProvision,
		@DisplayHeadline = @DisplayHeadline,
		@DisplayCollege = @DisplayCollege,
		@DisplayFaculty = @DisplayFaculty,
		@DisplayTeam = @DisplayTeam,
		@CriteriaTitle = @CriteriaTitle,
		@CriteriaOrder = @CriteriaOrder,
		@NatAvgAllAgesDesc = @NatAvgAllAgesDesc,
		@NatAvgAgeDesc = @NatAvgAgeDesc,
		@GroupByDesc = @GroupByDesc,
		@WhereClause = @WhereClause;
END