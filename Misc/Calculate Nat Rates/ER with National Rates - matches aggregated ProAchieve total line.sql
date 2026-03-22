SELECT
	PA.SummaryType,
	Leavers = SUM ( PA.IsLeaver ),
	Ach = SUM ( PA.IsAch ),
	AchPer = 
		CASE
			WHEN SUM ( PA.IsLeaver ) = 0 THEN 0
			ELSE 
				ROUND ( CAST ( SUM ( PA.IsAch ) AS FLOAT ) / CAST ( SUM ( PA.IsLeaver ) AS FLOAT ), 4 )
		END,
	AchPerNR = NR.AchNR
FROM PRA_ProAchieveSummaryData PA
LEFT JOIN (
	SELECT
		RTE.SummaryType,
		AchNR = ROUND ( SUM ( RTE.AchNR ) / COUNT ( 1.00 ), 4 )
	FROM (
		SELECT
			PA.SummaryType,
			PA.FrameworkCode,
			PA.FrameworkName,
			PA.ProgTypeCode,
			PA.ProgTypeShortName,
			PA.SSA1Code,
			PA.SSA2Code,
			Leavers = MAX ( PA.NatRate_Aim_Leave ),
			Ach = MAX ( PA.NatRate_Aim_Ach ),
			AchNR = MAX ( PA.NatRate_Aim_AchPer )
		FROM PRA_ProAchieveSummaryData PA
		WHERE
			PA.EndYear = '17/18'
			AND PA.SummaryType IN (
				'ER_Overall'
			)
		GROUP BY
			PA.SummaryType,
			PA.FrameworkCode,
			PA.FrameworkName,
			PA.ProgTypeCode,
			PA.ProgTypeShortName,
			PA.SSA1Code,
			PA.SSA2Code
		--ORDER BY
		--	PA.FrameworkName,
		--	PA.ProgTypeShortName
	) RTE
	GROUP BY	
		RTE.SummaryType
) NR
	ON NR.SummaryType = PA.SummaryType
WHERE
	PA.EndYear = '17/18'
	AND PA.SummaryType IN (
		'ER_Overall'
	)
GROUP BY
	PA.SummaryType,
	NR.AchNR