CREATE PROCEDURE [dbo].[SPR_PRA_UpdateUserDefinedFieldsNLAND]

AS
BEGIN
	SET NOCOUNT ON;

	UPDATE S
	SET
		UserDefined1 = 'Y',
		UserDefined2 = NULL,
		UserDefined3 = NULL,
		UserDefined4 = NULL,
		UserDefined5 = NULL
	FROM ALSNorthumberland ALS
	INNER JOIN NLAND_PROSQL.ProGeneral.dbo.Student S
		ON S.StudentID = ALS.StudentRef
		AND S.AcademicYearID = ALS.AcademicYear
END