CREATE PROCEDURE [dbo].[SPR_PRA_UpdateUserDefinedFields]

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AcademicYear NVARCHAR(5) = ''

	SET @AcademicYear = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')

	UPDATE S
	SET
		/*UserDefined1 = CASE WHEN SD.ALSRequired = 1 THEN 'Y' ELSE 'N' END,*/--Not using flag here but checking costs instead
		UserDefined1 = CASE WHEN COALESCE ( ALS.EstimatedCosts, 0 ) + COALESCE ( ALS.ActualCosts, 0 ) > 1 THEN 'Y' ELSE 'N' END,
		UserDefined2 = CASE WHEN SD.CareLeaver = 1 THEN 'Y' ELSE 'N' END,
		UserDefined3 = CASE WHEN SD.LookedAfter = 1 THEN 'Y' ELSE 'N' END,
		UserDefined4 = CASE WHEN SD.YoungCarer = 1 THEN 'Y' ELSE 'N' END,
		UserDefined5 = CASE WHEN SD.YoungParent = 1 THEN 'Y' ELSE 'N' END
	FROM besql05.ProGeneral.dbo.Student S
	INNER JOIN besql03.ProSolution.dbo.StudentDetail SD
		ON SD.RefNo = S.StudentID
		AND SD.AcademicYearID = S.AcademicYearID
	LEFT JOIN (
		SELECT
			SD.StudentDetailID,
			EstimatedCosts = 
				ROUND (
					COALESCE (
						SUM (
							CASE
								WHEN ALSI.Estimated = 1 THEN ALSI.Cost
								ELSE 0
							END
						),
						0
					)
				, 2 ),
			ActualCosts = 
				ROUND (
					COALESCE (
						SUM (
							CASE
								WHEN ALSI.Estimated = 0 THEN ALSI.Cost
								ELSE 0
							END
						),
						0
					)
				, 2 )
		FROM besql03.ProSolution.dbo.StudentDetail SD
		INNER JOIN besql03.ProSolution.dbo.SupportAssessment ALS
			ON ALS.StudentDetailID = SD.StudentDetailID
		INNER JOIN besql03.ProSolution.dbo.SupportAssessmentLink ALSL
			ON ALSL.SupportAssessmentID = ALS.SupportAssessmentID
		INNER JOIN besql03.ProSolution.dbo.SupportAssessmentItem ALSI
			ON ALSI.SupportAssessmentItemID = ALSL.SupportAssessmentItemID
		WHERE  
			SD.AcademicYearID = @AcademicYear
		GROUP BY
			SD.StudentDetailID
	) ALS
		ON ALS.StudentDetailID = SD.StudentDetailID
	WHERE
		S.AcademicYearID = @AcademicYear
END