--Info: https://www.gov.uk/government/publications/minimum-standards-2017-to-2018
USE QualityWarehouse

IF OBJECT_ID('dbo.ProAchieveMinStandards', 'U') IS NOT NULL 
	DROP TABLE dbo.ProAchieveMinStandards;

SELECT
	QualTypeCode = MINS.PG_QualSizeID,
	QualTypeName = QS.PG_QualSizeName,
	MinAchRateReqForCLAdultAndApps = MINS.ThresholdValue,
	SortOrder = QS.PG_QualSizeOrder
	INTO ProAchieveMinStandards
FROM SAMISDB007.ProAchieve.dbo.PM_MS_ThresholdValue MINS
INNER JOIN SAMISDB007.ProAchieve.dbo.PG_QualSize QS
	ON QS.PG_QualSizeID = MINS.PG_QualSizeID