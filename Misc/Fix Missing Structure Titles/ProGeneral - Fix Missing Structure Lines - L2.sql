UPDATE ST
SET
	ST.LevelName = NME.LevelName
FROM CCS_CollegeStructure ST
INNER JOIN (
	SELECT
		ST.Level2Code,
		ST.LevelName
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 2
		AND ST.LevelName 
		<> '-'
) NME
	ON NME.Level2Code = ST.Level2Code
WHERE
	ST.LevelNumber = 2
	AND ST.LevelName = '-'