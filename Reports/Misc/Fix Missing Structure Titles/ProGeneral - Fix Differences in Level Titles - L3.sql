UPDATE ST
SET
	ST.LevelName = NME.LevelName
--SELECT
--	ST.Level3Code,
--	ST.LevelName,
--	NME.LevelName
FROM CCS_CollegeStructure ST
INNER JOIN (
	SELECT
		ST.Level3Code,
		NumDups = COUNT ( DISTINCT ST.LevelName )
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 3
	GROUP BY
		ST.Level3Code
	HAVING
		COUNT ( DISTINCT ST.LevelName ) > 1
) DUPS
	ON DUPS.Level3Code = ST.Level3Code
INNER JOIN (
	SELECT DISTINCT
		ST.Level3Code,
		ST.LevelName,
		RowNum =
			ROW_NUMBER () OVER (
				PARTITION BY
					ST.Level3Code
				ORDER BY
					CASE
						WHEN ST.LevelName LIKE 'T%' THEN 1
						ELSE 2
					END
			)
	FROM CCS_CollegeStructure ST
	WHERE
		ST.LevelNumber = 3
) NME
	ON NME.Level3Code = ST.Level3Code
	AND NME.RowNum = 1
WHERE
	ST.LevelNumber = 3