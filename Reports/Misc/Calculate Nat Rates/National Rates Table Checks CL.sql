SELECT
	AGE.PG_AgeLSCName,
	QS.PG_QualSizeName,
	Leavers = SUM ( NR.BM_Count_Overall ),
	Ach = SUM ( NR.BM_Ach_Overall ),
	Comp = SUM ( NR.BM_Complete_Overall ),
	AchPer = 
		CASE
			WHEN ROUND ( SUM ( NR.BM_Count_Overall ), -1 ) = 0 THEN 0
			ELSE 
				ROUND ( CAST ( ROUND ( SUM ( NR.BM_Ach_Overall) , -1 ) AS FLOAT ) / CAST ( ROUND ( SUM ( NR.BM_Count_Overall ), -1 ) AS FLOAT ), 3 )
		END,
	AchPerNotRounded = 
		CASE
			WHEN SUM ( NR.BM_Count_Overall ) = 0 THEN 0
			ELSE 
				ROUND ( CAST ( SUM ( NR.BM_Ach_Overall) AS FLOAT ) / CAST ( SUM ( NR.BM_Count_Overall ) AS FLOAT ), 3 )
		END
FROM PG_NationalRates_CL_High_Overall NR
INNER JOIN PG_AgeLSC AGE
	ON AGE.PG_AgeLSCID = NR.PG_AgeLSCID
INNER JOIN PG_QualSize QS
	ON QS.PG_QualSizeID = NR.PG_QualSizeID
WHERE
	NR.PG_HybridEndYearID = '16/17'
	--AND NR.PG_CollegeTypeID = 0
	AND AGE.PG_AgeLSCName = '19 +'
GROUP BY
	AGE.PG_AgeLSCName,
	--NR.PG_NVQLevelCPRID
	--NR.PG_NVQLevelGroupID
	--NR.PM_MS_GroupID
	QS.PG_QualSizeName
	--NR.PG_SSA1ID
	--NR.PG_SSA2ID
	--NR.PG_SexID
	--NR.PG_EthnicityID
	--NR.PG_EthnicGroupID
	--NR.PG_EthnicityGroupQARID
	--NR.PG_DisabilityID
	--NR.PG_DifficultyOrDisabilityID
	--NR.GN_FullLevelCategoryID

--SELECT
--	Leavers = SUM ( NR.BM_Count_Overall ),
--	Ach = SUM ( NR.BM_AchCount_Overall ),
--	Comp = SUM ( NR.BM_AchComplete_Overall ),
--	AchPer = 
--		CASE
--			WHEN ROUND ( SUM ( NR.BM_Count_Overall ), -1 ) = 0 THEN 0
--			ELSE 
--				ROUND ( CAST ( ROUND ( SUM ( NR.BM_AchCount_Overall) , -1 ) AS FLOAT ) / CAST ( ROUND ( SUM ( NR.BM_Count_Overall ), -1 ) AS FLOAT ), 4 )
--		END
--FROM PG_NationalRates_CL_Qual_Overall NR
--WHERE
--	NR.PG_HybridEndYearID = '17/18'
--	AND NR.PG_CollegeTypeID = 0
--	--AND NR.PG_AgeLSCID IS NULL
--	--AND NR.PG_AimID IS NULL
--	--AND NR.PG_MapID IS NULL