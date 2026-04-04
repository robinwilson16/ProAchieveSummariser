CREATE OR ALTER PROCEDURE SPR_PRA_GenerateProAchieveSummaryData
	@ProviderID INT,
	@ProviderRef NVARCHAR(50),
	@AcademicYear NVARCHAR(5),
	@Mode NCHAR(1),
	@ProGeneralDatabaseLocation NVARCHAR(200),
	@ProAchieveDatabaseLocation NVARCHAR(200),
	@OutputTableLocation NVARCHAR(200),
	@UserDefinedTrueValue NVARCHAR(50),
	@ALSStudentUserDefinedField INT,
	@LookedAfterStudentUserDefinedField INT,
	@CareLeaverStudentUserDefinedField INT,
	@YoungCarerStudentUserDefinedField INT,
	@YoungParentStudentUserDefinedField INT,
	@GroupCodeEnrolmentUserDefinedField INT,
    @NumRowsChanged INT OUTPUT, 
	@ErrorCode INT OUTPUT

AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON;
	
	--DECLARE @ProviderID INT = 10005979 --Provider Ref of the college
	--DECLARE @ProviderRef NVARCHAR(50) = 'HSDC' --Reference to save into table in case title too long for charts etc.
	--DECLARE @AcademicYear NVARCHAR(5) = ''

	--SET @AcademicYear = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')
	--SET @AcademicYear = '25/26' --Override
	--DECLARE @Mode NCHAR(1) = 'I' --I=Insert new yearly ProAchieve data leaving data for other years, R=Replace table
	--DECLARE @ProGeneralDatabaseLocation NVARCHAR(200) = 'ProGeneral.dbo.' --Database/Linked Server location
	--DECLARE @ProAchieveDatabaseLocation NVARCHAR(200) = 'ProAchieve.dbo.' --Database/Linked Server location
	--DECLARE @OutputTableLocation NVARCHAR(200) = 'ProAchieveSummariser.dbo.' --Location where the resulting ProAchieve Summary Data table will be created
	--DECLARE @UserDefinedTrueValue NVARCHAR(50) = 'Y' --The value that indicates ALS is provided - e.g. Y/True
	--DECLARE @ALSStudentUserDefinedField INT = 1 --UDF where ALS is imported as Y/N
	--DECLARE @LookedAfterStudentUserDefinedField INT = 3
	--DECLARE @CareLeaverStudentUserDefinedField INT = 2
	--DECLARE @YoungCarerStudentUserDefinedField INT = 4
	--DECLARE @YoungParentStudentUserDefinedField INT = 5
	--DECLARE @GroupCodeEnrolmentUserDefinedField INT = 1 --UDF where the course group code is stored

	--DECLARE @NumRowsChanged INT
	--DECLARE @ErrorCode INT

	DECLARE @Message NVARCHAR(MAX);

	DECLARE @TableExists BIT = 1;
	DECLARE @NumExistingRecords INT = 0;

	DECLARE @SQLString NVARCHAR(MAX);
	DECLARE @SQLParams NVARCHAR(MAX);

	IF @Mode = 'R'
		IF OBJECT_ID('dbo.PRA_ProAchieveSummaryData', 'U') IS NOT NULL 
			BEGIN
				SET @SQLString = N'
					DROP TABLE dbo.PRA_ProAchieveSummaryData';

                SET @SQLParams = N'';

				EXECUTE sp_executesql 
                    @SQLString, 
                    @SQLParams;

				SET @TableExists = 0;
			END
	ELSE
		IF OBJECT_ID('dbo.PRA_ProAchieveSummaryData', 'U') IS NULL 
			SET @TableExists = 0;

	IF @Mode = 'R' OR @TableExists = 0
		BEGIN

			SET @SQLString = N'
				CREATE TABLE dbo.PRA_ProAchieveSummaryData(
					EndYear CHAR(5) NULL,
					AcademicYear VARCHAR(5) NOT NULL,
					StartYear VARCHAR(5) NOT NULL,
					ProvisionType VARCHAR(2) NOT NULL,
					SummaryType VARCHAR(7) NOT NULL,
					SummaryMeasure VARCHAR(12) NOT NULL,
					IsDefaultSummary INT NULL,
					IsArchivedSummary INT NULL,
					IsQSRSummary INT NULL,
					IsRulesAppliedSummary INT NULL,
					IsAllAimTypesSummary INT NULL,
					ProviderID VARCHAR(8) NOT NULL,
					ProviderRef VARCHAR(50) NULL,
					ProviderName VARCHAR(255) NULL,
					Summary VARCHAR(128) NULL,
					SummaryStatus VARCHAR(20) NULL,
					AcademicYears VARCHAR(50) NULL,
					NumYears INT NULL,
					LastAcademicYear VARCHAR(5) NULL,
					RulesApplied INT NULL,
					LastUpdated VARCHAR(20) NULL,
					LearnRefNumber VARCHAR(12) NOT NULL,
					LearnerName VARCHAR(255) NULL,
					Sex CHAR(1) NULL,
					AgeGroup VARCHAR(32) NULL,
					PostCodeUpliftCode VARCHAR(2) NULL,
					PostCodeUpliftName VARCHAR(50) NULL,
					PostCodeIsDisadvantaged INT NULL,
					PostCodeHome VARCHAR(8) NULL,
					PostCodeCurrent VARCHAR(8) NULL,
					PostCodeDelivery VARCHAR(8) NULL,
					PostCodeWardCode VARCHAR(20) NULL,
					PostCodeWardName VARCHAR(100) NULL,
					PostCodeDistrictCode VARCHAR(10) NULL,
					PostCodeDistrictName VARCHAR(50) NULL,
					PostCodeLEACode VARCHAR(10) NULL,
					PostCodeLEAName VARCHAR(50) NULL,
					PostCode1619Uplift FLOAT NULL,
					PostCodeAdultUplift FLOAT NULL,
					PostCodeAppUplift FLOAT NULL,
					PostCodeUpliftApplied FLOAT NULL,
					EthnicityCode CHAR(3) NULL,
					EthnicityName VARCHAR(62) NULL,
					EthnicityOrder INT NULL,
					EthnicGroupCode CHAR(2) NULL,
					EthnicGroupName VARCHAR(62) NULL,
					EthnicGroupOrder INT NULL,
					EthnicGroupQARCode CHAR(2) NOT NULL,
					EthnicGroupQARName VARCHAR(200) NULL,
					EthnicGroupQAROrder INT NULL,
					EthnicGroupSimpleCode VARCHAR(2) NULL,
					EthnicGroupSimpleName VARCHAR(9) NULL,
					EthnicGroupSimpleOrder INT NULL,
					HasDifficultyOrDisabilityCode CHAR(1) NULL,
					HasDifficultyOrDisabilityName VARCHAR(40) NULL,
					DifficultyCode VARCHAR(2) NULL,
					DifficultyName VARCHAR(80) NULL,
					DifficultyShortName VARCHAR(40) NULL,
					IsHighNeeds INT NULL,
					HasEducationalHealthCarePlanCode VARCHAR(3) NULL,
					HasEducationalHealthCarePlanName VARCHAR(100) NULL,
					HasEducationalHealthCarePlanShortName VARCHAR(100) NULL,
					LearningSupportFundCode VARCHAR(5) NULL,
					LearningSupportFundName VARCHAR(150) NULL,
					LearningSupportFundShortName VARCHAR(150) NULL,
					IsFreeMealsEligible INT NULL,
                    IsALSRequired INT NULL,
					IsLookedAfter INT NULL,
                    IsCareLeaver INT NULL,
                    IsYoungCarer INT NULL,
                    IsYoungParent INT NULL,
			'

			SET @SQLString += 
				N'
					CampusID VARCHAR(8) NULL,
					CollegeLevel1Code VARCHAR(24) NULL,
					CollegeLevel1Name VARCHAR(150) NULL,
					CollegeLevel2Code VARCHAR(24) NULL,
					CollegeLevel2Name VARCHAR(150) NULL,
					CollegeLevel3Code VARCHAR(24) NULL,
					CollegeLevel3Name VARCHAR(150) NULL,
					CollegeLevel4Code VARCHAR(24) NULL,
					CollegeLevel4Name VARCHAR(150) NULL,
					SubjectSectorArea1Code VARCHAR(5) NULL,
					SubjectSectorArea1Name VARCHAR(150) NULL,
					SubjectSectorArea2Code VARCHAR(5) NULL,
					SubjectSectorArea2Name VARCHAR(150) NULL,
					ProgTypeCode CHAR(2) NULL,
					ProgTypeShortName VARCHAR(32) NULL,
					ProgTypeName VARCHAR(50) NULL,
					StandardCode VARCHAR(5) NULL,
					StandardName VARCHAR(750) NULL,
					FrameworkCode VARCHAR(3) NULL,
					FrameworkName VARCHAR(163) NULL,
					PathwayCode INT NULL,
					PathwayName VARCHAR(255) NULL,
					CourseCode VARCHAR(40) NULL,
					CourseName VARCHAR(255) NULL,
					GroupCode VARCHAR(255) NULL,
					ProviderAimMonitoring1 VARCHAR(20) NULL,
					ProviderAimMonitoring2 VARCHAR(20) NULL,
					ProviderAimMonitoring3 VARCHAR(20) NULL,
					ProviderAimMonitoring4 VARCHAR(20) NULL,
					StartDate DATETIME NULL,
					ExpEndDate DATETIME NULL,
					ExpEndDatePlus90Days DATETIME NULL,
					ActEndDate DATETIME NULL,
					AchDate DATETIME NULL,
					StartPeriodID INT NULL,
					ExpEndPeriodID INT NULL,
					ActEndPeriodID INT NULL,
					CompletionStatusCode VARCHAR(1) NULL,
					CompletionStatusName VARCHAR(40) NULL,
					OutcomeCode VARCHAR(1) NULL,
					OutcomeName VARCHAR(40) NULL,
					SubcontractorCode VARCHAR(8) NULL,
					SubcontractorName VARCHAR(255) NULL,
					MinimumStandardThreshold INT,
					MinimumStandardType VARCHAR(24),
					MinimumStandardGroupCode VARCHAR(1) NULL,
					MinimumStandardsGroupName VARCHAR(1) NULL,
					SequenceNo INT NOT NULL,
			'

			SET @SQLString += 
				N'
					LearnAimRef VARCHAR(8) NULL,
					LearnAimTitle VARCHAR(254) NULL,
					LearningAimTypeCode CHAR(4) NULL,
					LearningAimTypeName VARCHAR(150) NULL,
					QualificationTypeCode VARCHAR(4) NULL,
					QualificationTypeName VARCHAR(64) NULL,
					AimTypeCode CHAR(1) NULL,
					AimTypeName VARCHAR(150) NULL,
					DurationCode VARCHAR(2) NULL,
					DurationName VARCHAR(40) NULL,
					DurationGroupCode VARCHAR(2) NULL,
					DurationGroupName VARCHAR(32) NULL,
					DurationTypeCode VARCHAR(16) NULL,
					DurationTypeName VARCHAR(32) NULL,
					DurationTypeGroupCode VARCHAR(2) NULL,
					DurationTypeGroupName VARCHAR(50) NULL,
					EngOrMathsCode VARCHAR(1) NULL,
					EngOrMathsName VARCHAR(7) NULL,
					NVQLevelCode VARCHAR(2) NULL,
					NVQLevelName VARCHAR(50) NULL,
					NVQLevelGroupCode CHAR(1) NULL,
					NVQLevelGroupName VARCHAR(48) NULL,
					LevelOfStudyCode VARCHAR(1) NULL,
					LevelOfStudyName VARCHAR(64) NULL,
					QOECode VARCHAR(3) NULL,
					QOEName VARCHAR(150) NULL,
					AwardingBody VARCHAR(20) NULL,
					Grade VARCHAR(8) NULL,
					FundingModelCode VARCHAR(5) NOT NULL,
					FundingModelName VARCHAR(16) NOT NULL,
					FundingStream VARCHAR(2) NULL,
					IsEFAFunded INT NOT NULL,
					IsAdvLearnLoanFunded INT NULL,
					IsStart INT NULL,
					IsLeaver INT NULL,
					IsLeaverBestCase INT NULL,
					LessonsExpected FLOAT NULL,
					LessonsAttended FLOAT NULL,
					AttendancePer FLOAT NULL,
					LessonsLate FLOAT NULL,
					PunctualityPer FLOAT NULL,
					IsXfr INT NULL,
					IsCont INT NULL,
					IsWdr INT NULL,
					IsWdrInQualifyingPeriod INT NULL,
					IsWdrAfterQualifyingPeriod INT NULL,
					IsPlannedBreak INT NOT NULL,
					IsOutOfFunding30 INT NOT NULL,
					IsOutOfFunding60 INT NOT NULL,
					IsOutOfFunding90 INT NOT NULL,
					IsComp INT NULL,
					IsRetInYr INT NULL,
					IsRet INT NULL,
					IsAch INT NULL,
					IsAchBestCase INT NULL,
					IsPassHigh INT NULL,
					IsPassAToC INT NULL,
					FrameworkStatusCode INT NULL,
					FrameworkStatusName VARCHAR(128),
					IsCompAwaitAch INT NULL,
			'

			SET @SQLString += 
				N'
					NART_GFE_Overall_Leave INT NULL,
					NART_GFE_Overall_RetPer FLOAT NULL,
					NART_GFE_Overall_AchPer FLOAT NULL,
					NART_GFE_Overall_PassPer FLOAT NULL,

					NART_ALL_Overall_Leave INT NULL,
					NART_ALL_Overall_RetPer FLOAT NULL,
					NART_ALL_Overall_AchPer FLOAT NULL,
					NART_ALL_Overall_PassPer FLOAT NULL,

					NART_GFE_Aim_Leave INT NULL,
					NART_GFE_Aim_Comp INT NULL,
					NART_GFE_Aim_RetPer FLOAT NULL,
					NART_GFE_Aim_Ach INT NULL,
					NART_GFE_Aim_AchPer FLOAT NULL,
					NART_GFE_Aim_Pass INT NULL,
					NART_GFE_Aim_PassPer FLOAT NULL,
					NART_ALL_Aim_Leave INT NULL,
					NART_ALL_Aim_Comp INT NULL,
					NART_ALL_Aim_RetPer FLOAT NULL,
					NART_ALL_Aim_Ach INT NULL,
					NART_ALL_Aim_AchPer FLOAT NULL,
					NART_ALL_Aim_Pass INT NULL,
					NART_ALL_Aim_PassPer FLOAT NULL,

					NART_GFE_Standard_Leave INT NULL,
					NART_GFE_Standard_RetPer FLOAT NULL,
					NART_GFE_Standard_AchPer FLOAT NULL,
					NART_GFE_Standard_PassPer FLOAT NULL,
					NART_ALL_Standard_Leave INT NULL,
					NART_ALL_Standard_RetPer FLOAT NULL,
					NART_ALL_Standard_AchPer FLOAT NULL,
					NART_ALL_Standard_PassPer FLOAT NULL,

					NART_GFE_Framework_Leave INT NULL,
					NART_GFE_Framework_RetPer FLOAT NULL,
					NART_GFE_Framework_AchPer FLOAT NULL,
					NART_GFE_Framework_PassPer FLOAT NULL,
					NART_ALL_Framework_Leave INT NULL,
					NART_ALL_Framework_RetPer FLOAT NULL,
					NART_ALL_Framework_AchPer FLOAT NULL,
					NART_ALL_Framework_PassPer FLOAT NULL,

					NART_GFE_FrameworkProgType_Leave INT NULL,
					NART_GFE_FrameworkProgType_RetPer FLOAT NULL,
					NART_GFE_FrameworkProgType_AchPer FLOAT NULL,
					NART_GFE_FrameworkProgType_PassPer FLOAT NULL,
					NART_ALL_FrameworkProgType_Leave INT NULL,
					NART_ALL_FrameworkProgType_RetPer FLOAT NULL,
					NART_ALL_FrameworkProgType_AchPer FLOAT NULL,
					NART_ALL_FrameworkProgType_PassPer FLOAT NULL,

					NART_GFE_FrameworkProgTypeSSA_Leave INT NULL,
					NART_GFE_FrameworkProgTypeSSA_RetPer FLOAT NULL,
					NART_GFE_FrameworkProgTypeSSA_AchPer FLOAT NULL,
					NART_GFE_FrameworkProgTypeSSA_PassPer FLOAT NULL,
					NART_ALL_FrameworkProgTypeSSA_Leave INT NULL,
					NART_ALL_FrameworkProgTypeSSA_RetPer FLOAT NULL,
					NART_ALL_FrameworkProgTypeSSA_AchPer FLOAT NULL,
					NART_ALL_FrameworkProgTypeSSA_PassPer FLOAT NULL,
			'

			SET @SQLString += 
				N'
					NART_GFE_Age_Leave INT NULL,
					NART_GFE_Age_RetPer FLOAT NULL,
					NART_GFE_Age_AchPer FLOAT NULL,
					NART_GFE_Age_PassPer FLOAT NULL,
					NART_ALL_Age_Leave INT NULL,
					NART_ALL_Age_RetPer FLOAT NULL,
					NART_ALL_Age_AchPer FLOAT NULL,
					NART_ALL_Age_PassPer FLOAT NULL,

					NART_GFE_Sex_Leave INT NULL,
					NART_GFE_Sex_RetPer FLOAT NULL,
					NART_GFE_Sex_AchPer FLOAT NULL,
					NART_GFE_Sex_PassPer FLOAT NULL,
					NART_ALL_Sex_Leave INT NULL,
					NART_ALL_Sex_RetPer FLOAT NULL,
					NART_ALL_Sex_AchPer FLOAT NULL,
					NART_ALL_Sex_PassPer FLOAT NULL,

					NART_GFE_SexAge_Leave INT NULL,
					NART_GFE_SexAge_RetPer FLOAT NULL,
					NART_GFE_SexAge_AchPer FLOAT NULL,
					NART_GFE_SexAge_PassPer FLOAT NULL,
					NART_ALL_SexAge_Leave INT NULL,
					NART_ALL_SexAge_RetPer FLOAT NULL,
					NART_ALL_SexAge_AchPer FLOAT NULL,
					NART_ALL_SexAge_PassPer FLOAT NULL,

					NART_GFE_Level_Leave INT NULL,
					NART_GFE_Level_RetPer FLOAT NULL,
					NART_GFE_Level_AchPer FLOAT NULL,
					NART_GFE_Level_PassPer FLOAT NULL,
					NART_ALL_Level_Leave INT NULL,
					NART_ALL_Level_RetPer FLOAT NULL,
					NART_ALL_Level_AchPer FLOAT NULL,
					NART_ALL_Level_PassPer FLOAT NULL,

					NART_GFE_LevelAge_Leave INT NULL,
					NART_GFE_LevelAge_RetPer FLOAT NULL,
					NART_GFE_LevelAge_AchPer FLOAT NULL,
					NART_GFE_LevelAge_PassPer FLOAT NULL,
					NART_ALL_LevelAge_Leave INT NULL,
					NART_ALL_LevelAge_RetPer FLOAT NULL,
					NART_ALL_LevelAge_AchPer FLOAT NULL,
					NART_ALL_LevelAge_PassPer FLOAT NULL,

                    NART_GFE_LevelGroup_Leave INT NULL,
					NART_GFE_LevelGroup_RetPer FLOAT NULL,
					NART_GFE_LevelGroup_AchPer FLOAT NULL,
					NART_GFE_LevelGroup_PassPer FLOAT NULL,
					NART_ALL_LevelGroup_Leave INT NULL,
					NART_ALL_LevelGroup_RetPer FLOAT NULL,
					NART_ALL_LevelGroup_AchPer FLOAT NULL,
					NART_ALL_LevelGroup_PassPer FLOAT NULL,

					NART_GFE_LevelGroupAge_Leave INT NULL,
					NART_GFE_LevelGroupAge_RetPer FLOAT NULL,
					NART_GFE_LevelGroupAge_AchPer FLOAT NULL,
					NART_GFE_LevelGroupAge_PassPer FLOAT NULL,
					NART_ALL_LevelGroupAge_Leave INT NULL,
					NART_ALL_LevelGroupAge_RetPer FLOAT NULL,
					NART_ALL_LevelGroupAge_AchPer FLOAT NULL,
					NART_ALL_LevelGroupAge_PassPer FLOAT NULL,
			'

			SET @SQLString += 
				N'
					NART_GFE_QualType_Leave INT NULL,
					NART_GFE_QualType_RetPer FLOAT NULL,
					NART_GFE_QualType_AchPer FLOAT NULL,
					NART_GFE_QualType_PassPer FLOAT NULL,
					NART_ALL_QualType_Leave INT NULL,
					NART_ALL_QualType_RetPer FLOAT NULL,
					NART_ALL_QualType_AchPer FLOAT NULL,
					NART_ALL_QualType_PassPer FLOAT NULL,

					NART_GFE_QualTypeAge_Leave INT NULL,
					NART_GFE_QualTypeAge_RetPer FLOAT NULL,
					NART_GFE_QualTypeAge_AchPer FLOAT NULL,
					NART_GFE_QualTypeAge_PassPer FLOAT NULL,
					NART_ALL_QualTypeAge_Leave INT NULL,
					NART_ALL_QualTypeAge_RetPer FLOAT NULL,
					NART_ALL_QualTypeAge_AchPer FLOAT NULL,
					NART_ALL_QualTypeAge_PassPer FLOAT NULL,

					NART_GFE_Ethnicity_Leave INT NULL,
					NART_GFE_Ethnicity_RetPer FLOAT NULL,
					NART_GFE_Ethnicity_AchPer FLOAT NULL,
					NART_GFE_Ethnicity_PassPer FLOAT NULL,
					NART_ALL_Ethnicity_Leave INT NULL,
					NART_ALL_Ethnicity_RetPer FLOAT NULL,
					NART_ALL_Ethnicity_AchPer FLOAT NULL,
					NART_ALL_Ethnicity_PassPer FLOAT NULL,

                    NART_GFE_EthnicityAge_Leave INT NULL,
					NART_GFE_EthnicityAge_RetPer FLOAT NULL,
					NART_GFE_EthnicityAge_AchPer FLOAT NULL,
					NART_GFE_EthnicityAge_PassPer FLOAT NULL,
					NART_ALL_EthnicityAge_Leave INT NULL,
					NART_ALL_EthnicityAge_RetPer FLOAT NULL,
					NART_ALL_EthnicityAge_AchPer FLOAT NULL,
					NART_ALL_EthnicityAge_PassPer FLOAT NULL,

					NART_GFE_EthnicGroup_Leave INT NULL,
					NART_GFE_EthnicGroup_RetPer FLOAT NULL,
					NART_GFE_EthnicGroup_AchPer FLOAT NULL,
					NART_GFE_EthnicGroup_PassPer FLOAT NULL,
					NART_ALL_EthnicGroup_Leave INT NULL,
					NART_ALL_EthnicGroup_RetPer FLOAT NULL,
					NART_ALL_EthnicGroup_AchPer FLOAT NULL,
					NART_ALL_EthnicGroup_PassPer FLOAT NULL,

                    NART_GFE_EthnicGroupAge_Leave INT NULL,
					NART_GFE_EthnicGroupAge_RetPer FLOAT NULL,
					NART_GFE_EthnicGroupAge_AchPer FLOAT NULL,
					NART_GFE_EthnicGroupAge_PassPer FLOAT NULL,
					NART_ALL_EthnicGroupAge_Leave INT NULL,
					NART_ALL_EthnicGroupAge_RetPer FLOAT NULL,
					NART_ALL_EthnicGroupAge_AchPer FLOAT NULL,
					NART_ALL_EthnicGroupAge_PassPer FLOAT NULL,
			'

			SET @SQLString += 
				N'
					NART_GFE_SSA1_Leave INT NULL,
					NART_GFE_SSA1_RetPer FLOAT NULL,
					NART_GFE_SSA1_AchPer FLOAT NULL,
					NART_GFE_SSA1_PassPer FLOAT NULL,
					NART_ALL_SSA1_Leave INT NULL,
					NART_ALL_SSA1_RetPer FLOAT NULL,
					NART_ALL_SSA1_AchPer FLOAT NULL,
					NART_ALL_SSA1_PassPer FLOAT NULL,

					NART_GFE_SSA1Age_Leave INT NULL,
					NART_GFE_SSA1Age_RetPer FLOAT NULL,
					NART_GFE_SSA1Age_AchPer FLOAT NULL,
					NART_GFE_SSA1Age_PassPer FLOAT NULL,
					NART_ALL_SSA1Age_Leave INT NULL,
					NART_ALL_SSA1Age_RetPer FLOAT NULL,
					NART_ALL_SSA1Age_AchPer FLOAT NULL,
					NART_ALL_SSA1Age_PassPer FLOAT NULL,

					NART_GFE_SSA2_Leave INT NULL,
					NART_GFE_SSA2_RetPer FLOAT NULL,
					NART_GFE_SSA2_AchPer FLOAT NULL,
					NART_GFE_SSA2_PassPer FLOAT NULL,
					NART_ALL_SSA2_Leave INT NULL,
					NART_ALL_SSA2_RetPer FLOAT NULL,
					NART_ALL_SSA2_AchPer FLOAT NULL,
					NART_ALL_SSA2_PassPer FLOAT NULL,

					NART_GFE_SSA2Age_Leave INT NULL,
					NART_GFE_SSA2Age_RetPer FLOAT NULL,
					NART_GFE_SSA2Age_AchPer FLOAT NULL,
					NART_GFE_SSA2Age_PassPer FLOAT NULL,
					NART_ALL_SSA2Age_Leave INT NULL,
					NART_ALL_SSA2Age_RetPer FLOAT NULL,
					NART_ALL_SSA2Age_AchPer FLOAT NULL,
					NART_ALL_SSA2Age_PassPer FLOAT NULL,

					NART_GFE_DifDis_Leave INT NULL,
					NART_GFE_DifDis_RetPer FLOAT NULL,
					NART_GFE_DifDis_AchPer FLOAT NULL,
					NART_GFE_DifDis_PassPer FLOAT NULL,
					NART_ALL_DifDis_Leave INT NULL,
					NART_ALL_DifDis_RetPer FLOAT NULL,
					NART_ALL_DifDis_AchPer FLOAT NULL,
					NART_ALL_DifDis_PassPer FLOAT NULL,

                    NART_GFE_DifDisAge_Leave INT NULL,
					NART_GFE_DifDisAge_RetPer FLOAT NULL,
					NART_GFE_DifDisAge_AchPer FLOAT NULL,
					NART_GFE_DifDisAge_PassPer FLOAT NULL,
					NART_ALL_DifDisAge_Leave INT NULL,
					NART_ALL_DifDisAge_RetPer FLOAT NULL,
					NART_ALL_DifDisAge_AchPer FLOAT NULL,
					NART_ALL_DifDisAge_PassPer FLOAT NULL
				)'

			SET @SQLParams = N'';

            EXECUTE sp_executesql 
                @SQLString, 
                @SQLParams;

			SET @SQLString = N'
				CREATE CLUSTERED INDEX CI_PRA_ProAchieveSummaryData 
					ON PRA_ProAchieveSummaryData (
						EndYear, 
						SummaryType, 
						ProviderID, 
						CollegeLevel1Code, 
						CollegeLevel2Code, 
						CollegeLevel3Code,
						CollegeLevel4Code
					)'

			SET @SQLParams = N'';

            EXECUTE sp_executesql 
                @SQLString, 
                @SQLParams;


			--Additional index to speed up reporting
			SET @SQLString = N'
				CREATE NONCLUSTERED INDEX NI_PRA_ProAchieveSummaryData 
					ON PRA_ProAchieveSummaryData (
						SummaryType, 
						EndYear
					)
				INCLUDE (
					ProviderID, 
					ProviderName, 
					AgeGroup, 
					CollegeLevel1Code, 
					CollegeLevel1Name,
					CollegeLevel2Code, 
					CollegeLevel2Name,
					CollegeLevel3Code,
					CollegeLevel3Name,
					CollegeLevel4Code,
					CollegeLevel4Name,
					SubcontractorCode, 
					IsLeaver, 
					IsComp, 
					IsAch
				)'

			SET @SQLParams = N'';

            EXECUTE sp_executesql 
                @SQLString, 
                @SQLParams;

		END
	ELSE
		BEGIN
			SET @SQLString = N'
				SELECT
					@NumExistingRecordsOUT = SUM ( 1 )
				FROM ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData PA
				WHERE
					PA.ProviderID = @ProviderID
					AND PA.EndYear = @AcademicYear';

            SET @SQLParams = 
                N'@ProviderID INT,
				@AcademicYear NVARCHAR(5),
                @NumExistingRecordsOUT INT OUTPUT';

            EXECUTE sp_executesql 
                @SQLString, 
                @SQLParams,
				@ProviderID = @ProviderID, 
                @AcademicYear = @AcademicYear, 
                @NumExistingRecordsOUT = @NumExistingRecords OUTPUT;

			IF @NumExistingRecords > 0
				BEGIN
					SET @SQLString = N'
						DELETE FROM ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData
						WHERE
							ProviderID = @ProviderID
							AND EndYear = @AcademicYear';

					SET @SQLParams = 
                        N'@ProviderID INT,
						@AcademicYear NVARCHAR(5)';

                    EXECUTE sp_executesql 
                        @SQLString, 
                        @SQLParams,
						@ProviderID = @ProviderID, 
                        @AcademicYear = @AcademicYear;
				END
		END

	SET @Message = N'5%% - Table Set Up';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert CL Overall
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_CLOverall
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
        
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;

	SET @Message = N'15%% - CL Overall ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert CL Timely
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_CLTimely
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
        
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;

	SET @Message = N'30%% - CL Timely ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert ER Overall
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_EROverall
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
    
 
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;

	SET @Message = N'50%% - ER Overall ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert ER Timely
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_ERTimely
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
        
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;
	
	SET @Message = N'70%% - ER Timely ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert HE Overall
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_HEOverall
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
        
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;

	SET @Message = N'85%% - HE Overall ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	--Insert HE Timely
	SET @SQLString = N'
		EXEC SPR_PRA_ProAchieveSummaryData_HETimely
			@ProviderRef,
			@AcademicYear, 
			@ProGeneralDatabaseLocation,
			@ProAchieveDatabaseLocation,
			@OutputTableLocation,
			@UserDefinedTrueValue,
			@ALSStudentUserDefinedField,
			@LookedAfterStudentUserDefinedField,
			@CareLeaverStudentUserDefinedField,
			@YoungCarerStudentUserDefinedField,
			@YoungParentStudentUserDefinedField,
			@GroupCodeEnrolmentUserDefinedField,
            @NumRowsChanged, 
	        @ErrorCode';

    SET @SQLParams = 
            N'@ProviderRef NVARCHAR(50),
			@AcademicYear NVARCHAR(5),
            @ProGeneralDatabaseLocation NVARCHAR(200),
            @ProAchieveDatabaseLocation NVARCHAR(200),
			@OutputTableLocation NVARCHAR(200),
			@UserDefinedTrueValue NVARCHAR(50),
			@ALSStudentUserDefinedField INT,
			@LookedAfterStudentUserDefinedField INT,
			@CareLeaverStudentUserDefinedField INT,
			@YoungCarerStudentUserDefinedField INT,
			@YoungParentStudentUserDefinedField INT,
			@GroupCodeEnrolmentUserDefinedField INT,
            @NumRowsChanged INT OUTPUT, 
	        @ErrorCode INT OUTPUT';
        
    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef, 
        @AcademicYear = @AcademicYear, 
        @ProGeneralDatabaseLocation = @ProGeneralDatabaseLocation, 
        @ProAchieveDatabaseLocation = @ProAchieveDatabaseLocation,
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField,
        @NumRowsChanged = @NumRowsChanged OUTPUT, 
        @ErrorCode = @ErrorCode OUTPUT;

	SET @Message = N'100%% - HE Timely ' + @AcademicYear + ' Imported';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;

	SET @Message = N'' + @AcademicYear + ' Import Complete';
	RAISERROR ( @Message, 10, 1 ) WITH NOWAIT;
END