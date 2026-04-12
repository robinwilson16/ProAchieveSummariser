CREATE TABLE Config (
	ConfigID NVARCHAR(50) NOT NULL,
	Description NVARCHAR(200) NULL,
	Value NVARCHAR(10) NULL,
	CONSTRAINT Config_PK PRIMARY KEY CLUSTERED 
	(
		ConfigID ASC
	)
)

INSERT INTO Config
SELECT
	ConfigID = 'PRA_AcademicYearID',
	Description = 'Academic Year for the ProAchieve Data Summariser and other ProAchieve scripts',
	Value = '25/26'