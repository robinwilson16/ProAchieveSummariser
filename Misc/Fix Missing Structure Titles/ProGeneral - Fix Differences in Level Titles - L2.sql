UPDATE ST
SET
	ST.LevelName = NME.LevelName
--SELECT
--	ST.Level2Code,
--	ST.LevelName,
--	NME.LevelName
FROM CCS_CollegeStructure ST
INNER JOIN (
	SELECT
		ST.Level2Code,
		NumDups = COUNT ( DISTINCT ST.LevelName )
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 2
	GROUP BY
		ST.Level2Code
	HAVING
		COUNT ( DISTINCT ST.LevelName ) > 1
) DUPS
	ON DUPS.Level2Code = ST.Level2Code
INNER JOIN (
	SELECT DISTINCT
		ST.Level2Code,
		ST.LevelName,
		RowNum =
			ROW_NUMBER () OVER (
				PARTITION BY
					ST.Level2Code
				ORDER BY
					CASE
						WHEN ST.LevelName LIKE 'F0%' THEN 1
						ELSE 2
					END
			)
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 2
) NME
	ON NME.Level2Code = ST.Level2Code
	AND NME.RowNum = 1
WHERE
	ST.LevelNumber = 2