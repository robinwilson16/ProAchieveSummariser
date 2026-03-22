SELECT
	NR.PG_HybridEndYearID,
	ETHG.PG_EthnicGroupSimpleID,
	Leave = SUM ( NR.BM_Count_Overall ),
	Comp = NULL,
	Ach = NULL,
	RetPer = SUM ( NR.BM_RetCount_Overall ) / COUNT ( ETHG.PG_EthnicGroupSimpleID ) / 100,
	PassPer = SUM ( NR.BM_AchComplete_Overall ) / COUNT ( ETHG.PG_EthnicGroupSimpleID ) / 100,
	AchPer = SUM ( NR.BM_AchCount_Overall ) / COUNT ( ETHG.PG_EthnicGroupSimpleID ) / 100
FROM PG_NationalRates_CL_High_Overall NR
INNER JOIN PG_Ethnicity ETH
	ON ETH.PG_EthnicityID = NR.PG_EthnicityID
INNER JOIN PG_EthnicGroup ETHG
	ON ETHG.PG_EthnicGroupID = ETH.PG_EthnicGroupID
WHERE
	NR.PG_HybridEndYearID = '18/19'
	AND NR.PG_CollegeTypeID = 2
	AND NR.PG_AgeLSCID IS NULL
	AND NR.PG_NVQLevelCPRID IS NULL
	AND NR.PG_NVQLevelGroupID IS NULL
	AND NR.PM_MS_GroupID IS NULL
	AND NR.PG_QualSizeID IS NULL
	AND NR.PG_SSA1ID IS NULL
	AND NR.PG_SSA2ID IS NULL
	AND NR.PG_SexID IS NULL
	AND NR.PG_EthnicityID IS NOT NULL
	AND NR.PG_EthnicGroupID IS NULL
	AND NR.PG_DisabilityID IS NULL
	AND NR.PG_LearningDifficultyID IS NULL
	AND NR.PG_DifficultyOrDisabilityID IS NULL
	AND NR.GN_FullLevelCategoryID IS NULL
	AND NR.PG_EthnicityGroupQARID IS NULL
GROUP BY
	NR.PG_HybridEndYearID,
	ETHG.PG_EthnicGroupSimpleID