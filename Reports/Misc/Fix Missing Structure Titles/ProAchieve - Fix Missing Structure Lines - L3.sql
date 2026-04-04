UPDATE ST
SET
	ST.GN_Structure3IYName = NME.GN_Structure3IYName,
	ST.GN_Structure3IYShortName = NME.GN_Structure3IYShortName
--SELECT
--	ST.PG_AcademicYearID,
--	ST.GN_Structure3IYID,
--	ST.GN_Structure3IYName,
--	ST.GN_Structure3IYShortName,
--	ST.GN_Structure3IYOrder,
--	NME.GN_Structure3IYName,
--	NME.GN_Structure3IYShortName
FROM GN_Structure3IY ST
INNER JOIN (
	SELECT DISTINCT
		ST.GN_Structure3IYID,
		ST.GN_Structure3IYName,
		ST.GN_Structure3IYShortName
	FROM GN_Structure3IY ST
	WHERE
		ST.GN_Structure3IYName <> '-'
) NME
	ON NME.GN_Structure3IYID = ST.GN_Structure3IYID
WHERE
	ST.GN_Structure3IYName = '-'



