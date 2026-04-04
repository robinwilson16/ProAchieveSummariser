UPDATE ST
SET
	ST.LevelName = NME.LevelName
FROM CCS_CollegeStructure ST
INNER JOIN (
	SELECT DISTINCT
		ST.Level3Code,
		ST.LevelName
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 3
		AND ST.LevelName 
		<> '-'
) NME
	ON NME.Level3Code = ST.Level3Code
WHERE
	ST.LevelNumber = 3
	AND ST.LevelName = '-'