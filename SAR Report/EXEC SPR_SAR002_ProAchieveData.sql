--DECLARE @EndYear NVARCHAR(5) = '19/20'
--DECLARE @SummaryCourseType NVARCHAR(2) = 'CL'
--DECLARE @SummaryType NVARCHAR(20) = 'Overall'
--DECLARE @SummaryMeasure NVARCHAR(20) = 'RulesApplied'
--DECLARE @College NVARCHAR(50) = 'ALL'
--DECLARE @Fac NVARCHAR(50) = 'F02, F03'
--DECLARE @Team NVARCHAR(50) = 'ALL'
--DECLARE @SubcontractedProvision BIT = 1
--DECLARE @DisplayHeadline BIT = 1
--DECLARE @DisplayCollege BIT = 1
--DECLARE @DisplayFaculty BIT = 1
--DECLARE @DisplayTeam BIT = 1



SET NOCOUNT ON;
DECLARE @CriteriaTitle NVARCHAR(255) = NULL
DECLARE @CriteriaOrder INT = NULL
DECLARE @NatAvgAllAges NVARCHAR(50) = NULL
DECLARE @NatAvgAllAgesDesc NVARCHAR(50) = NULL
DECLARE @NatAvgAge NVARCHAR(50) = NULL
DECLARE @NatAvgAgeDesc NVARCHAR(50) = NULL
DECLARE @GroupBy NVARCHAR(255) = NULL
DECLARE @GroupByDesc NVARCHAR(255) = NULL
DECLARE @WhereClause NVARCHAR(255) = NULL

DROP TABLE IF EXISTS #SarData; 
CREATE TABLE #SarData (
	EndYear NVARCHAR(5) NULL,
	EndYearLastYear NVARCHAR(5) NULL,
	EndYear2YearsAgo NVARCHAR(5) NULL,
	CriteriaTitle NVARCHAR(255) NOT NULL,
	CriteriaOrder INT NOT NULL,
	Criteria NVARCHAR(255) NULL,
	SortGroup INT NOT NULL,
	SortOrder INT NOT NULL,
	Title NVARCHAR(50) NOT NULL,
	College NVARCHAR(255) NULL,
	Fac NVARCHAR(255) NULL,
	Team NVARCHAR(255) NULL,
	AgeGroup NVARCHAR(32) NULL,
	Leavers2YearsAgo INT NULL,
	Ret2YearsAgo FLOAT NULL,
	Ach2YearsAgo FLOAT NULL,
	Pass2YearsAgo FLOAT NULL,
	LeaversLastYear INT NULL,
	RetLastYear FLOAT NULL,
	AchLastYear FLOAT NULL,
	PassLastYear FLOAT NULL,
	LeaversThisYear INT NULL,
	RetThisYear FLOAT NULL,
	AchThisYear FLOAT NULL,
	PassThisYear FLOAT NULL,
	RetNatRateThisYear FLOAT NULL,
	AchNatRateThisYear FLOAT NULL,
	PassVarianceLastYear FLOAT NULL,
	PassVarianceNR FLOAT NULL,
	PassRAGRating CHAR(1) NULL,
	AchVarianceLastYear FLOAT NULL,
	AchVarianceNR FLOAT NULL,
	AchRAGRating CHAR(1) NULL,
	NatAvgAllAgesDesc NVARCHAR(50) NULL,
	NatAvgAgeDesc NVARCHAR(50) NULL,
	GroupByDesc NVARCHAR(255) NULL
)

SET @CriteriaTitle = 'Headline'
SET @CriteriaOrder = 1
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.EndYear IS NOT NULL THEN '''' ELSE '''' END'
SET @GroupByDesc = ''
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

IF @SummaryCourseType = 'CL'
BEGIN
	SET @CriteriaTitle = 'EFA Study Programme'
	SET @CriteriaOrder = 2
	SET @NatAvgAllAges = 'Yr'
	SET @NatAvgAllAgesDesc = 'Year'
	SET @NatAvgAge = 'Age'
	SET @NatAvgAgeDesc = 'Year + Age Group'
	SET @GroupBy = '
		CASE
			WHEN PA.QualTypeCode IN (
				5, 6, 7, 8, 11
			)
				THEN ''Academic''
			ELSE ''Vocational''
		END'
	SET @GroupByDesc = 'Course Type'
	SET @WhereClause = 
		'AND PA.FundModelCode = ''1619''
		AND PA.AimTypeCode = ''5'''
	INSERT INTO #SarData
	EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause
END


IF @SummaryCourseType = 'CL'
BEGIN
	SET @CriteriaTitle = 'Maths and English'
	SET @CriteriaOrder = 3
	SET @NatAvgAllAges = 'QualType'
	SET @NatAvgAllAgesDesc = 'Year + Qual Type'
	SET @NatAvgAge = 'QualTypeAge'
	SET @NatAvgAgeDesc = 'Year + Qual Type + Age Group'
	SET @GroupBy = 'COALESCE ( PA.QualTypeName, ''-- Unknown --'' )'
	SET @GroupByDesc = 'Functional Skills / GCSE'
	SET @WhereClause = 'AND PA.QualTypeCode IN ( 7, 9 )'
	INSERT INTO #SarData
	EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause
END

IF @SummaryCourseType = 'CL'
BEGIN
	SET @CriteriaTitle = 'Level'
	SET @CriteriaOrder = 4
	SET @NatAvgAllAges = 'Level'
	SET @NatAvgAllAgesDesc = 'Year + Level'
	SET @NatAvgAge = 'LevelAge'
	SET @NatAvgAgeDesc = 'Year + Level + Age Group'
	SET @GroupBy = 'CASE WHEN PA.NVQLevelGrpName = ''Other (including X, M & Unspecified)'' THEN ''Other'' ELSE PA.NVQLevelGrpName END'
	SET @GroupByDesc = 'Level'
	SET @WhereClause = ''
	INSERT INTO #SarData
	EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause
END

IF @SummaryCourseType = 'ER'
BEGIN
	SET @CriteriaTitle = 'Level'
	SET @CriteriaOrder = 4
	SET @NatAvgAllAges = 'Level'
	SET @NatAvgAllAgesDesc = 'Year + Prog Type'
	SET @NatAvgAge = 'LevelAge'
	SET @NatAvgAgeDesc = 'Year + Prog Type + Age Group'
	SET @GroupBy = 'PA.ProgTypeName'
	SET @GroupByDesc = 'Programme Type'
	SET @WhereClause = ''
	INSERT INTO #SarData
	EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause
END

SET @CriteriaTitle = 'Gender'
SET @CriteriaOrder = 5
SET @NatAvgAllAges = 'Gender'
SET @NatAvgAllAgesDesc = 'Year + Gender'
SET @NatAvgAge = 'GenderAge'
SET @NatAvgAgeDesc = 'Year + Gender + Age Group'
SET @GroupBy = 'PA.Gender'
SET @GroupByDesc = 'Gender'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'LLDD'
SET @CriteriaOrder = 6
SET @NatAvgAllAges = 'DifDis'
SET @NatAvgAllAgesDesc = 'Year + Dif/Dis'
SET @NatAvgAge = 'DifDisAge'
SET @NatAvgAgeDesc = 'Year + Dif/Dis + Age Group'
SET @GroupBy = 'PA.DiffDissName'
SET @GroupByDesc = 'Difficulty / Disability'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'High Needs'
SET @CriteriaOrder = 7
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsHighNeeds = 1 THEN ''High Needs'' ELSE ''Not High Needs'' END'
SET @GroupByDesc = 'High Needs'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Free Meals'
SET @CriteriaOrder = 8
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsFreeMealsEligible = 1 THEN ''Free School Meals'' ELSE ''Not Free School Meals'' END'
SET @GroupByDesc = 'Free Meals'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Looked After'
SET @CriteriaOrder = 9
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsLookedAfter = 1 THEN ''Looked After'' ELSE ''Not Looked After'' END'
SET @GroupByDesc = 'Looked After'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Care Leaver'
SET @CriteriaOrder = 10
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsCareLeaver = 1 THEN ''Care Leaver'' ELSE ''Not Care Leaver'' END'
SET @GroupByDesc = 'Care Leaver'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Young Carer'
SET @CriteriaOrder = 11
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsYoungCarer = 1 THEN ''Young Carer'' ELSE ''Not Young Carer'' END'
SET @GroupByDesc = 'Young Carer'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Young Parent'
SET @CriteriaOrder = 12
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsYoungParent = 1 THEN ''Young Parent'' ELSE ''Not Young Parent'' END'
SET @GroupByDesc = 'Young Parent'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause


SET @CriteriaTitle = 'Ethnic Group'
SET @CriteriaOrder = 13
SET @NatAvgAllAges = 'EthnicGroup'
SET @NatAvgAllAgesDesc = 'Year + Ethnic Group'
SET @NatAvgAge = 'EthnicGroupAge'
SET @NatAvgAgeDesc = 'Year + Ethnic Group + Age Group'
SET @GroupBy = 'PA.EthnicGroupSimpleName'
SET @GroupByDesc = 'Ethnic Group'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'Ethnicity'
SET @CriteriaOrder = 14
SET @NatAvgAllAges = 'Ethnicity'
SET @NatAvgAllAgesDesc = 'Year + Ethnicity'
SET @NatAvgAge = 'EthnicityAge'
SET @NatAvgAgeDesc = 'Year + Ethnicity + Age Group'
SET @GroupBy = 'PA.EthnicityName'
SET @GroupByDesc = 'Ethnicity'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

IF @SummaryCourseType = 'CL'
BEGIN
	SET @CriteriaTitle = 'Qual Type'
	SET @CriteriaOrder = 15
	SET @NatAvgAllAges = 'QualType'
	SET @NatAvgAllAgesDesc = 'Year + Qual Type'
	SET @NatAvgAge = 'QualTypeAge'
	SET @NatAvgAgeDesc = 'Year + Qual Type + Age Group'
	SET @GroupBy = 'COALESCE ( PA.QualTypeName, ''-- Unknown --'' )'
	SET @GroupByDesc = 'Qualification Type'
	SET @WhereClause = ''
	INSERT INTO #SarData
	EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause
END

SET @CriteriaTitle = 'SSA1'
SET @CriteriaOrder = 16
SET @NatAvgAllAges = 'SSA1'
SET @NatAvgAllAgesDesc = 'Year + SSA1'
SET @NatAvgAge = 'SSA1Age'
SET @NatAvgAgeDesc = 'Year + SSA1 + Age Group'
SET @GroupBy = 'PA.SSA1Code + '' - '' + PA.SSA1Name'
SET @GroupByDesc = 'Subject Sector Area 1'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'SSA2'
SET @CriteriaOrder = 17
SET @NatAvgAllAges = 'SSA2'
SET @NatAvgAllAgesDesc = 'Year + SSA2'
SET @NatAvgAge = 'SSA2Age'
SET @NatAvgAgeDesc = 'Year + SSA2 + Age Group'
SET @GroupBy = 'PA.SSA2Code + '' - '' + PA.SSA2Name'
SET @GroupByDesc = 'Subject Sector Area 2'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SET @CriteriaTitle = 'ALS'
SET @CriteriaOrder = 18
SET @NatAvgAllAges = 'Yr'
SET @NatAvgAllAgesDesc = 'Year'
SET @NatAvgAge = 'Age'
SET @NatAvgAgeDesc = 'Year + Age Group'
SET @GroupBy = 'CASE WHEN PA.IsALSRequired = 1 THEN ''ALS Required'' ELSE ''ALS Not Required'' END'
SET @GroupByDesc = 'Additional Learning Support'
SET @WhereClause = ''
INSERT INTO #SarData
EXEC EPNE.dbo.SPR_SAR002_ProAchieveData @EndYear, @SummaryCourseType, @SummaryType, @SummaryMeasure, @College, @Fac, @Team, @SubcontractedProvision, @DisplayHeadline, @DisplayCollege, @DisplayFaculty, @DisplayTeam, @CriteriaTitle, @CriteriaOrder, @NatAvgAllAges, @NatAvgAllAgesDesc, @NatAvgAge, @NatAvgAgeDesc, @GroupBy, @GroupByDesc, @WhereClause

SELECT *
FROM #SarData