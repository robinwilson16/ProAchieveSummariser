DECLARE @AcademicYear VARCHAR(5) = '22/23'



--Retention
DECLARE @LastYear VARCHAR(5) = CAST ( CAST ( LEFT ( @AcademicYear, 2 ) AS INT ) - 1 AS VARCHAR(2) ) + '/' + CAST ( CAST ( RIGHT ( @AcademicYear, 2 ) AS INT ) - 1 AS VARCHAR(2) )
DECLARE @TwoYearsAgo VARCHAR(5) = CAST ( CAST ( LEFT ( @AcademicYear, 2 ) AS INT ) - 2 AS VARCHAR(2) ) + '/' + CAST ( CAST ( RIGHT ( @AcademicYear, 2 ) AS INT ) - 2 AS VARCHAR(2) )
DECLARE @ThreeYearsAgo VARCHAR(5) = CAST ( CAST ( LEFT ( @AcademicYear, 2 ) AS INT ) - 3 AS VARCHAR(2) ) + '/' + CAST ( CAST ( RIGHT ( @AcademicYear, 2 ) AS INT ) - 3 AS VARCHAR(2) )

--DROP TABLE IF EXISTS #Retention
SELECT
	RET.AimRef,

	RetInYrThisYear = MAX ( CASE WHEN RET.YearRef = 'ThisYear' THEN RET.RetInYrPer ELSE NULL END ),
	RetThisYear = MAX ( CASE WHEN RET.YearRef = 'ThisYear' THEN RET.RetPer ELSE NULL END ),
	AchThisYear = MAX ( CASE WHEN RET.YearRef = 'ThisYear' THEN RET.AchPer ELSE NULL END ),
	PassThisYear = MAX ( CASE WHEN RET.YearRef = 'ThisYear' THEN RET.PassPer ELSE NULL END ),

	RetInYrLastYear = MAX ( CASE WHEN RET.YearRef = 'LastYear' THEN RET.RetInYrPer ELSE NULL END ),
	RetLastYear = MAX ( CASE WHEN RET.YearRef = 'LastYear' THEN RET.RetPer ELSE NULL END ),
	AchLastYear = MAX ( CASE WHEN RET.YearRef = 'LastYear' THEN RET.AchPer ELSE NULL END ),
	PassLastYear = MAX ( CASE WHEN RET.YearRef = 'LastYear' THEN RET.PassPer ELSE NULL END ),

	RetInYrTwoYearsAgo = MAX ( CASE WHEN RET.YearRef = 'TwoYearsAgo' THEN RET.RetInYrPer ELSE NULL END ),
	RetTwoYearsAgo = MAX ( CASE WHEN RET.YearRef = 'TwoYearsAgo' THEN RET.RetPer ELSE NULL END ),
	AchTwoYearsAgo = MAX ( CASE WHEN RET.YearRef = 'TwoYearsAgo' THEN RET.AchPer ELSE NULL END ),
	PassTwoYearsAgo = MAX ( CASE WHEN RET.YearRef = 'TwoYearsAgo' THEN RET.PassPer ELSE NULL END ),

	RetInYrThreeYearsAgo = MAX ( CASE WHEN RET.YearRef = 'ThreeYearsAgo' THEN RET.RetInYrPer ELSE NULL END ),
	RetThreeYearsAgo = MAX ( CASE WHEN RET.YearRef = 'ThreeYearsAgo' THEN RET.RetPer ELSE NULL END ),
	AchThreeYearsAgo = MAX ( CASE WHEN RET.YearRef = 'ThreeYearsAgo' THEN RET.AchPer ELSE NULL END ),
	PassThreeYearsAgo = MAX ( CASE WHEN RET.YearRef = 'ThreeYearsAgo' THEN RET.PassPer ELSE NULL END )
	--INTO #Retention
FROM (
	SELECT
		PA.AimRef,
		PA.EndYear,
		YearRef =
			CASE
				WHEN PA.EndYear = @AcademicYear THEN 'ThisYear'
				WHEN PA.EndYear = @LastYear THEN 'LastYear'
				WHEN PA.EndYear = @TwoYearsAgo THEN 'TwoYearsAgo'
				WHEN PA.EndYear = @ThreeYearsAgo THEN 'ThreeYearsAgo'
				ELSE '-- ERROR --'
			END,
		RetInYrPer = 
			ROUND ( 
				CASE
					WHEN SUM ( PA.IsStart ) = 0 THEN 0
					ELSE
						CAST ( SUM ( PA.IsRetInYr ) AS FLOAT )
						/
						CAST ( SUM ( PA.IsStart ) AS FLOAT )
				END,
				3
			),
		RetPer = 
			ROUND ( 
				CASE
					WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
					ELSE
						CAST ( SUM ( PA.IsComp ) AS FLOAT )
						/
						CAST ( SUM ( PA.IsLeaver ) AS FLOAT )
				END,
				3
			),
		AchPer = 
			ROUND ( 
				CASE
					WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
					ELSE
						CAST ( SUM ( PA.IsAch ) AS FLOAT )
						/
						CAST ( SUM ( PA.IsLeaver ) AS FLOAT )
				END,
				3
			),
		PassPer = 
			ROUND ( 
				CASE
					WHEN SUM ( PA.IsComp ) = 0 THEN 0
					ELSE
						CAST ( SUM ( PA.IsAch ) AS FLOAT )
						/
						CAST ( SUM ( PA.IsComp ) AS FLOAT )
				END,
				3
			)
	FROM ProAchieveDataSummariser.dbo.PRA_ProAchieveSummaryData PA
	WHERE
		PA.EndYear BETWEEN 
			@ThreeYearsAgo
			AND @AcademicYear
		--AND PA.ProviderID = @ProviderID
		AND PA.SummaryType = 'Overall'
		AND PA.SummaryMeasure = 
			CASE
				WHEN PA.ProvisionType = 'CL' THEN 'RulesApplied'
				ELSE 'AllAims'
			END
	GROUP BY
		PA.EndYear,
		PA.AimRef
) RET
GROUP BY
	RET.AimRef