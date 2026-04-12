CREATE OR ALTER PROCEDURE SPR_PRA_ProAchieveSummaryData_CLOverall
	@ProviderRef NVARCHAR(50),
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
	@ErrorCode INT OUTPUT
AS
BEGIN
	SET XACT_ABORT OFF; --To fix error: New transaction is not allowed because there are other threads running in the session
	SET NOCOUNT ON;
	
	--DECLARE @ProviderID INT = 10005979 --Provider Ref of the college
	--DECLARE @ProviderRef NVARCHAR(50) = 'HSDC' --Reference to save into table in case title too long for charts etc.
	--DECLARE @AcademicYear NVARCHAR(5) = ''

	--SET @AcademicYear = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')
	--SET @AcademicYear = '25/26' --Override
	--DECLARE @Mode CHAR(1) = 'I' --I=Insert new yearly ProAchieve data leaving data for other years, R=Replace table
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


    DECLARE @SQLString NVARCHAR(MAX);
    DECLARE @SQLParams NVARCHAR(MAX);

	SET @SQLString = 
        N'
		DECLARE @NatRateYear NVARCHAR(5) = NULL

		SELECT
			@NatRateYear = 
				CASE
					WHEN @AcademicYear >= MAX ( NR.PG_HybridEndYearID ) THEN MAX ( NR.PG_HybridEndYearID )
					ELSE @AcademicYear
				END
		FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Overall NR


		--National Achievement Rates
		DROP TABLE IF EXISTS #NARTs
		SELECT
			NR.PG_HybridEndYearID,
			NR.PG_CollegeTypeID,
			NR.PG_AgeLSCID,
			NR.PG_NVQLevelGroupID,
			NR.PG_QualSizeID,
			NR.PG_SSA1ID,
			NR.PG_SSA2ID,
			NR.PG_SexID,
			NR.PG_EthnicityID,
			NR.PG_DifficultyOrDisabilityID,
			NR.BM_Count_Overall,
			NR.BM_AchCount_Overall,
			NR.BM_RetCount_Overall,
			NR.BM_AchComplete_Overall
			INTO #NARTs
		FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
		WHERE
			NR.PG_HybridEndYearID = @NatRateYear
			AND NR.PG_CollegeTypeID IN ( 0, 2 )


		DROP TABLE IF EXISTS #NARTsQual
		SELECT
			NR.PG_HybridEndYearID,
			NR.PG_CollegeTypeID,
			NR.PG_AgeLSCID,
			NR.PG_AimID,
			NR.PG_MapID,
			NR.BM_Count_Overall,
			NR.BM_AchCount_Overall,
			NR.BM_RetCount_Overall,
			NR.BM_AchComplete_Overall
			INTO #NARTsQual
		FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Overall NR
		WHERE
			NR.PG_HybridEndYearID = @NatRateYear
			AND NR.PG_CollegeTypeID IN ( 0, 2 )


		--Main Query
		INSERT INTO ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData WITH (TABLOCKX)
		SELECT
			EndYear = CL.PG_HybridEndYearID,
			AcademicYear = CL.PG_AcademicYearID,
			StartYear = CL.StartYear,
			ProvisionType = ''CL'',
			SummaryType = ''Overall'',
			SummaryMeasure =
                CASE
                    WHEN 
                        MYS.DefaultSummary = 1
                        AND MYS.IsArchived = 0
                        AND MYS.IsQSRSummary = 0
                        AND MYS.RulesApplied = 1
                        AND MYS.IncludeAllAimTypes = 0
                        THEN ''RulesApplied''
                    WHEN 
                        MYS.DefaultSummary = 0
                        AND MYS.IsArchived = 0
                        AND MYS.IsQSRSummary = 0
                        AND MYS.RulesApplied = 0
                        AND MYS.IncludeAllAimTypes = 1
                        THEN ''AllAims''
                    WHEN 
                        MYS.DefaultSummary = 0
                        AND MYS.IsArchived = 0
                        AND MYS.IsQSRSummary = 1
                        AND MYS.RulesApplied = 1
                        AND MYS.IncludeAllAimTypes = 0
                        THEN ''QAR''
                    ELSE ''ERROR''
                END,
			IsDefaultSummary = MYS.DefaultSummary,
			IsArchivedSummary = MYS.IsArchived,
			IsQSRSummary = MYS.IsQSRSummary,
			IsRulesAppliedSummary = MYS.RulesApplied,
			IsAllAimTypesSummary = MYS.IncludeAllAimTypes,
			ProviderID = MYS.PG_ProviderID,
			ProviderRef = @ProviderRef,
			ProviderName = MYS.PG_ProviderName,
			Summary = MYS.Description,
			SummaryStatus = MYS.Status,
			AcademicYears = MYS.CL_MYSName,
			NumYears = MYS.Years,
			LastAcademicYear = MYS.LastAcademicYearID,
			RulesApplied = MYS.RulesApplied,
			LastUpdated = MYS.LastUpdated,
	'
    
    SET @SQLString += 
        N'
			LearnRefNumber = CL.PG_StudentID,
			LearnerName = CL.StudentName,
			Sex = CL.PG_SexID,
			AgeGroup = 
				CASE
					WHEN AGE.PG_AgeLSCName = ''16-18'' THEN ''16 - 18''
					WHEN AGE.PG_AgeLSCName = ''19+'' THEN ''19 +''
					ELSE AGE.PG_AgeLSCName
				END,
			PostCodeUpliftCode = CL.PG_UpliftID,
			PostCodeUpliftName = UPL.ShortDescription,
			PostCodeIsDisadvantaged = CASE WHEN UPL.Disadvantaged = ''Y'' THEN 1 ELSE 0 END,
			PostCodeHome = CL.HomePostcode,
			PostCodeCurrent = CL.CurrentPostcode,
			PostCodeDelivery = CL.DeliveryPostcode,
			PostCodeWardCode = PCW.WardCode,
			PostCodeWardName = PCW.WardName,
			PostCodeDistrictCode = PCW.DistrictCode,
			PostCodeDistrictName = PCW.DistrictName,
			PostCodeLEACode = PCW.LEACode,
			PostCodeLEAName = PCW.LEAName,
			PostCodeUplift1619 = COALESCE ( PCU.EFA_UPLIFT, 1 ),
			PostCodeUpliftAdult = COALESCE ( PCU.SFA_UPLIFT, 1 ),
			PostCodeUpliftApp = COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 ),
			PostCodeUpliftApplied =
				CASE
					WHEN CL.PG_FundingStreamID = ''25'' THEN COALESCE ( PCU.EFA_UPLIFT, 1 )
					WHEN CL.PG_FundingStreamID = ''35'' THEN COALESCE ( PCU.SFA_UPLIFT, 1 )
					WHEN CL.PG_FundingStreamID = ''36'' THEN COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 )
					ELSE 1
				END,
			EthnicityCode = ETH.PG_EthnicityID,
			EthnicityName = ETH.PG_EthnicityName,
			EthnicityOrder = ETH.PG_EthnicityOrder,
			EthnicGroupCode = ETHG.PG_EthnicGroupID,
			EthnicGroupName = ETHG.PG_EthnicGroupName,
			EthnicGroupOrder = ETHG.PG_EthnicGroupOrder,
			EthnicGroupQARCode = ETHQ.PG_EthnicityGroupQARID,
			EthnicGroupQARName = ETHQ.PG_EthnicityGroupQARName,
			EthnicGroupQAROrder = ETHQ.PG_EthnicityGroupQAROrder,
			EthnicGroupSimpleCode = ETHGS.PG_EthnicGroupSimpleID,
			EthnicGroupSimpleName = ETHGS.PG_EthnicGroupSimpleName,
			EthnicGroupSimpleOrder = ETHGS.PG_EthnicGroupSimpleOrder,
			HasDifficultyOrDisabilityCode = CL.PG_DifficultyOrDisabilityID,
			HasDifficultyOrDisabilityName = DIF.ShortDescription,
			DifficultyCode = CL.PG_DisabilityID,
			DifficultyName = DIS.Description,
			DifficultyShortName = DIS.ShortDescription,
			IsHighNeeds = COALESCE ( FAM.PG_LearnFAMTypeHNSID, 0 ),
			HasEducationalHealthCarePlanCode = FAM.PG_LearnFAMTypeEHCID,
			HasEducationalHealthCarePlanName = EHC.PG_LearnFAMTypeEHCName,
			HasEducationalHealthCarePlanShortName = EHC.PG_LearnFAMTypeEHCShortName,
			LearningSupportFundCode = FAMLD.PG_LearnDelFAMTypeLSFID,
			LearningSupportFundName = LSF.PG_LearnDelFAMTypeLSFName,
			LearningSupportFundShortName = LSF.PG_LearnDelFAMTypeLSFShortName,
			IsFreeMealsEligible = CASE WHEN FAM.PG_LearnFAMTypeFMEID IS NOT NULL THEN 1 ELSE 0 END,
	'
    
    SET @SQLString += 
        N'
			IsALSRequired = 
				CASE 
					WHEN
						CASE 
							WHEN @ALSStudentUserDefinedField = 1 THEN STU.UserDefined1
							WHEN @ALSStudentUserDefinedField = 2 THEN STU.UserDefined2
							WHEN @ALSStudentUserDefinedField = 3 THEN STU.UserDefined3
							WHEN @ALSStudentUserDefinedField = 4 THEN STU.UserDefined4
							WHEN @ALSStudentUserDefinedField = 5 THEN STU.UserDefined5
						END
					= @UserDefinedTrueValue THEN 1 
					ELSE 0 
				END,
			IsLookedAfter = 
				CASE 
					WHEN
						CASE 
							WHEN @LookedAfterStudentUserDefinedField = 1 THEN STU.UserDefined1
							WHEN @LookedAfterStudentUserDefinedField = 2 THEN STU.UserDefined2
							WHEN @LookedAfterStudentUserDefinedField = 3 THEN STU.UserDefined3
							WHEN @LookedAfterStudentUserDefinedField = 4 THEN STU.UserDefined4
							WHEN @LookedAfterStudentUserDefinedField = 5 THEN STU.UserDefined5
						END
					= @UserDefinedTrueValue THEN 1 
					ELSE 0 
				END,
			IsCareLeaver = 
				CASE 
					WHEN
						CASE 
							WHEN @CareLeaverStudentUserDefinedField = 1 THEN STU.UserDefined1
							WHEN @CareLeaverStudentUserDefinedField = 2 THEN STU.UserDefined2
							WHEN @CareLeaverStudentUserDefinedField = 3 THEN STU.UserDefined3
							WHEN @CareLeaverStudentUserDefinedField = 4 THEN STU.UserDefined4
							WHEN @CareLeaverStudentUserDefinedField = 5 THEN STU.UserDefined5
						END
					= @UserDefinedTrueValue THEN 1 
					ELSE 0 
				END,
			IsYoungCarer = 
				CASE 
					WHEN
						CASE 
							WHEN @YoungCarerStudentUserDefinedField = 1 THEN STU.UserDefined1
							WHEN @YoungCarerStudentUserDefinedField = 2 THEN STU.UserDefined2
							WHEN @YoungCarerStudentUserDefinedField = 3 THEN STU.UserDefined3
							WHEN @YoungCarerStudentUserDefinedField = 4 THEN STU.UserDefined4
							WHEN @YoungCarerStudentUserDefinedField = 5 THEN STU.UserDefined5
						END
					= @UserDefinedTrueValue THEN 1 
					ELSE 0 
				END,
			IsYoungParent = 
				CASE 
					WHEN
						CASE 
							WHEN @YoungParentStudentUserDefinedField = 1 THEN STU.UserDefined1
							WHEN @YoungParentStudentUserDefinedField = 2 THEN STU.UserDefined2
							WHEN @YoungParentStudentUserDefinedField = 3 THEN STU.UserDefined3
							WHEN @YoungParentStudentUserDefinedField = 4 THEN STU.UserDefined4
							WHEN @YoungParentStudentUserDefinedField = 5 THEN STU.UserDefined5
						END
					= @UserDefinedTrueValue THEN 1 
					ELSE 0 
				END,
	'

    SET @SQLString += 
        N'
			CampusID = COALESCE ( STU.CampusID, ''-'' ),
			CollegeLevel1Code = COALESCE ( L1.GN_Structure1IYID, ''-'' ),
			CollegeLevel1Name = COALESCE ( L1.GN_Structure1IYName, ''-- Unknown --'' ),
			CollegeLevel2Code = COALESCE ( L2.GN_Structure2IYID, ''-'' ),
			CollegeLevel2Name = COALESCE ( L2.GN_Structure2IYName, ''-- Unknown --'' ),
			CollegeLevel3Code = COALESCE ( L3.GN_Structure3IYID, ''-'' ),
			CollegeLevel3Name = COALESCE ( L3.GN_Structure3IYName, ''-- Unknown --'' ),
			CollegeLevel4Code = COALESCE ( L4.GN_Structure4IYID, ''-'' ),
			CollegeLevel4Name = COALESCE ( L4.GN_Structure4IYName, ''-- Unknown --'' ),
	'
    
    SET @SQLString += 
        N'
			SubjectSectorArea1Code = CL.PG_SSA1ID,
			SubjectSectorArea1Name = SSA1.SSA_Tier1_Desc,
			SubjectSectorArea2Code = CL.PG_SSA2ID,
			SubjectSectorArea2Name = SSA2.SSA_Tier2_Desc,
			ProgTypeCode = NULL,
			ProgTypeShortName = NULL,
			ProgTypeName = NULL,
			StandardCode = NULL,
			StandardName = NULL,
			FrameworkCode = NULL,
			FrameworkName = NULL,
			PathwayCode = NULL,
			PathwayName = NULL,
			CourseCode = CL.PG_AggCourseID,
			CourseName = CRS.PG_AggCourseName,
			GroupCode = CL.EnrolmentUserDefined1,
			ProviderAimMonitoring1 = ENR.ProviderAimMonitoring1,
			ProviderAimMonitoring2 = ENR.ProviderAimMonitoring2,
			ProviderAimMonitoring3 = ENR.AddProviderAimMonitoring1,
			ProviderAimMonitoring4 = ENR.AddProviderAimMonitoring2,
			StartDate = CL.StartDate,
			ExpEndDate = CL.PlannedEndDate,
			ExpEndDatePlus90Days = CL.PlannedEndDate_Plus90Days,
			ActEndDate = CL.ActualEndDate,
			AchDate = NULL,
			StartPeriodID = NULL,
			ExpEndPeriodID = NULL,
			ActEndPeriodID = NULL,
			CompletionStatusCode = CL.PG_CompletionID,
			CompletionStatusName = CMP.ShortDescription,
			OutcomeCode = CL.PG_OutcomeID,
			OutcomeName = OC.ShortDescription,
			SubcontractorCode = CL.PG_SubContractorID,
			SubcontractorName = NULL,
			MinimumStandardThreshold = MINS.ThresholdValue,
			MinimumStandardType = MINS.Type,
			MinimumStandardGroupCode = CL.Minimum_Standards_GroupID,
			MinimumStandardsGroupName = MSTD.Minimum_Standards_GroupName,
			SequenceNo = CL.SequenceNo,
    '
    
    SET @SQLString += 
        N'
			LearnAimRef = AIM.GN_AimID,
			LearnAimTitle = AIM.GN_AimName,
			LearningAimTypeCode = CL.PG_QType1ID,
			LearningAimTypeName = QT.PG_LearningAimTypeName,
			QualificationTypeCode = CL.PG_QualSizeID,
			QualificationTypeName = QS.PG_QualSizeName,
			AimTypeCode = CL.PG_ILRAimTypeID,
			AimTypeName = AIMT.PG_ILRAimTypeName,
			DurationCode = CL.PG_DurationID,
			DurationName = DUR.PG_DurationName,
			DurationGroupCode = CL.PG_DurationGroupID,
			DurationGroupName = DURG.PG_DurationGroupName,
			DurationTypeCode = CL.PG_DurationTypeID,
			DurationTypeName = DURT.PG_DurationTypeName,
			DurationTypeGroupCode = CL.PG_DurationTypeGroupID,
			DurationTypeGroupName = DURTG.PG_DurationTypeGroupName,

			EngOrMathsCode = COALESCE ( CL.PG_MathsEnglishID, ''X'' ),
			EngOrMathsName = COALESCE ( EM.PG_MathsEnglishName, ''Neither'' ),
			NVQLevelCode = CL.PG_NVQLevelID,
			NVQLevelName = LVLC.PG_NVQLevelCPRName,
			NVQLevelGroupCode = LVL.PG_NVQLevelGroupID,
			NVQLevelGroupName = LVLG.Description,
			LevelOfStudyCode = NULL,
			LevelOfStudyName = NULL,
			QOECode = NULL,
			QOEName = NULL,
			AwardingBody = AIM.PG_AwardBodyID,
			Grade = CL.PG_GradeID,

			FundingModelCode = 
				CASE
					WHEN CL.FundType = ''16-19 (excluding Apprenticeships)'' THEN ''1619''
					WHEN CL.FundType = ''Adult skills'' THEN ''ADULT''
					WHEN CL.FundType = ''24+ Loan'' THEN ''LOAN''
					ELSE ''X''
				END,
			FundingModelName = 
				CASE
					WHEN CL.FundType = ''16-19 (excluding Apprenticeships)'' THEN ''16-19 Funded''
					WHEN CL.FundType = ''Adult skills'' THEN ''Adult Funded''
					WHEN CL.FundType = ''24+ Loan'' THEN ''Loan Funded''
					ELSE ''-- Unknown --''
				END,
			FundingStream = CL.PG_FundingStreamID,
			IsEFAFunded = CASE WHEN CL.IsEFA_Funded = ''Y'' THEN 1 ELSE 0 END,
			IsAdvLearnLoanFunded = CL.Loan_Funded,
			IsStart = CL.CLStartOverall,
			IsLeaver = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 1 
					ELSE 
						CL.P_Count_OverallQSRExclude 
				END,
			IsLeaverBestCase = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 1 
					ELSE 
						CL.P_Count_Overall_BestCase
				END,
			LessonsExpected = CL.Att_Exp,
			LessonsAttended = CL.Att_Act,
			AttendancePer = 
				ROUND (
					CASE
						WHEN CL.Att_Exp = 0 THEN 0
						ELSE CAST ( CL.Att_Act AS FLOAT ) / CAST ( CL.Att_Exp AS FLOAT )
					END
				, 4 ),
			LessonsLate = CL.Att_Lat,
			PunctualityPer = 
				ROUND (
					CASE
						WHEN CL.Att_Act = 0 THEN 0
						ELSE 100 - CAST ( CL.Att_Lat AS FLOAT ) / CAST ( CL.Att_Act AS FLOAT )
					END
				, 4 ),
			IsXfr = CL.PVXfr,
			IsCont = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 0
					ELSE 
						CL.PVCont
				END,
			IsWdr = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 1
					ELSE 
						CASE WHEN CL.IsWithdrawnAll = ''Y'' THEN 1 ELSE 0 END
				END,
			IsWdrInQualifyingPeriod = CASE WHEN CL.IsWithdrawnInQualPeriod = ''Y'' THEN 1 ELSE 0 END,
			IsWdrAfterQualifyingPeriod = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 1
					ELSE 
						CASE WHEN CL.IsWithdrawnAfterQualPeriod = ''Y'' THEN 1 ELSE 0 END
				END,
			IsPlannedBreak = CL.P_Plan_Break_Overall,
			IsOutOfFunding30 = 
				CASE
					WHEN CL.ContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, CL.PlannedEndDate, CAST ( GetDate() AS DATE ) ) <= 30 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsOutOfFunding60 = 
				CASE
					WHEN CL.ContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, CL.PlannedEndDate, CAST ( GetDate() AS DATE ) ) BETWEEN 31 AND 60 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsOutOfFunding90 = 
				CASE
					WHEN CL.ContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, CL.PlannedEndDate, CAST ( GetDate() AS DATE ) ) BETWEEN 61 AND 90 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsComp = CL.P_Complete_OverallQSRExclude,
			IsRetInYr = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN 0
					ELSE 
						CL.PVCont + CL.P_Complete_OverallQSRExclude
				END,
			IsRet = 
				CASE 
					WHEN 
						CL.CLOverdue = 1 
						AND CL.QSRExclude_Overall = 0 
						AND CL.P_Count_OverallQSRExclude = 0 
						THEN CL.P_Complete_Overall
					ELSE 
						CL.PVCont + CL.P_Complete_OverallQSRExclude
				END,
			IsAch = CL.P_Ach_OverallQSRExclude,
			IsAchBestCase = CL.P_Ach_Overall_BestCase,
			IsPassHigh = CL.PVHigh,
			IsPassAToC = CL.CLPassRateAC_Overall,
			FrameworkStatusCode = NULL,
			FrameworkStatusName = NULL,
			IsCompAwaitAch = CL.P_CompUnknown,
	'

    SET @SQLString += 
        N'
			NART_GFE_Overall_Leave = NRG_YR.BM_Count_Overall,
			NART_GFE_Overall_RetPer = NRG_YR.BM_RetCount_Overall / 100,
			NART_GFE_Overall_AchPer = NRG_YR.BM_AchCount_Overall / 100,
			NART_GFE_Overall_PassPer = NRG_YR.BM_AchComplete_Overall / 100,
			NART_ALL_Overall_Leave = NRA_YR.BM_Count_Overall,
			NART_ALL_Overall_RetPer = NRA_YR.BM_RetCount_Overall / 100,
			NART_ALL_Overall_AchPer = NRA_YR.BM_AchCount_Overall / 100,
			NART_ALL_Overall_PassPer = NRA_YR.BM_AchComplete_Overall / 100,

			NART_GFE_Aim_Leave = NRG_AIM.BM_Count_Overall,
			NART_GFE_Aim_Comp = ROUND ( ( CAST ( NRG_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIM.BM_RetCount_Overall, 0 ),
			NART_GFE_Aim_RetPer = NRG_AIM.BM_RetCount_Overall / 100,
			NART_GFE_Aim_Ach = ROUND ( ( CAST ( NRG_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIM.BM_AchCount_Overall, 0 ),
			NART_GFE_Aim_AchPer = NRG_AIM.BM_AchCount_Overall / 100,
			NART_GFE_Aim_Pass = ROUND ( ( CAST ( NRG_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIM.BM_AchComplete_Overall, 0 ),
			NART_GFE_Aim_PassPer = NRG_AIM.BM_AchComplete_Overall / 100,
			NART_ALL_Aim_Leave = NRA_AIM.BM_Count_Overall,
			NART_ALL_Aim_Comp = ROUND ( ( CAST ( NRA_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIM.BM_RetCount_Overall, 0 ),
			NART_ALL_Aim_RetPer = NRA_AIM.BM_RetCount_Overall / 100,
			NART_ALL_Aim_Ach = ROUND ( ( CAST ( NRA_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIM.BM_AchCount_Overall, 0 ),
			NART_ALL_Aim_AchPer = NRA_AIM.BM_AchCount_Overall / 100,
			NART_ALL_Aim_Pass = ROUND ( ( CAST ( NRA_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIM.BM_AchComplete_Overall, 0 ),
			NART_ALL_Aim_PassPer = NRA_AIM.BM_AchComplete_Overall / 100,

			NART_GFE_AimAge_Leave = NRG_AIMAGE.BM_Count_Overall,
			NART_GFE_AimAge_Comp = ROUND ( ( CAST ( NRG_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIMAGE.BM_RetCount_Overall, 0 ),
			NART_GFE_AimAge_RetPer = NRG_AIMAGE.BM_RetCount_Overall / 100,
			NART_GFE_AimAge_Ach = ROUND ( ( CAST ( NRG_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIMAGE.BM_AchCount_Overall, 0 ),
			NART_GFE_AimAge_AchPer = NRG_AIMAGE.BM_AchCount_Overall / 100,
			NART_GFE_AimAge_Pass = ROUND ( ( CAST ( NRG_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRG_AIMAGE.BM_AchComplete_Overall, 0 ),
			NART_GFE_AimAge_PassPer = NRG_AIMAGE.BM_AchComplete_Overall / 100,
			NART_ALL_AimAge_Leave = NRA_AIMAGE.BM_Count_Overall,
			NART_ALL_AimAge_Comp = ROUND ( ( CAST ( NRA_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIMAGE.BM_RetCount_Overall, 0 ),
			NART_ALL_AimAge_RetPer = NRA_AIMAGE.BM_RetCount_Overall / 100,
			NART_ALL_AimAge_Ach = ROUND ( ( CAST ( NRA_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIMAGE.BM_AchCount_Overall, 0 ),
			NART_ALL_AimAge_AchPer = NRA_AIMAGE.BM_AchCount_Overall / 100,
			NART_ALL_AimAge_Pass = ROUND ( ( CAST ( NRA_AIMAGE.BM_Count_Overall AS FLOAT ) / 100 ) * NRA_AIMAGE.BM_AchComplete_Overall, 0 ),
			NART_ALL_AimAge_PassPer = NRA_AIMAGE.BM_AchComplete_Overall / 100,

			NART_GFE_Standard_Leave = NULL,
			NART_GFE_Standard_RetPer = NULL,
			NART_GFE_Standard_AchPer = NULL,
			NART_GFE_Standard_PassPer = NULL,
			NART_ALL_Standard_Leave = NULL,
			NART_ALL_Standard_RetPer = NULL,
			NART_ALL_Standard_AchPer = NULL,
			NART_ALL_Standard_PassPer = NULL,

			NART_GFE_Framework_Leave = NULL,
			NART_GFE_Framework_RetPer = NULL,
			NART_GFE_Framework_AchPer = NULL,
			NART_GFE_Framework_PassPer = NULL,
			NART_ALL_Framework_Leave = NULL,
			NART_ALL_Framework_RetPer = NULL,
			NART_ALL_Framework_AchPer = NULL,
			NART_ALL_Framework_PassPer = NULL,

			NART_GFE_FrameworkProgType_Leave = NULL,
			NART_GFE_FrameworkProgType_RetPer = NULL,
			NART_GFE_FrameworkProgType_AchPer = NULL,
			NART_GFE_FrameworkProgType_PassPer = NULL,
			NART_ALL_FrameworkProgType_Leave = NULL,
			NART_ALL_FrameworkProgType_RetPer = NULL,
			NART_ALL_FrameworkProgType_AchPer = NULL,
			NART_ALL_FrameworkProgType_PassPer = NULL,

			NART_GFE_FrameworkProgTypeSSA_Leave = NULL,
			NART_GFE_FrameworkProgTypeSSA_RetPer = NULL,
			NART_GFE_FrameworkProgTypeSSA_AchPer = NULL,
			NART_GFE_FrameworkProgTypeSSA_PassPer = NULL,
			NART_ALL_FrameworkProgTypeSSA_Leave = NULL,
			NART_ALL_FrameworkProgTypeSSA_RetPer = NULL,
			NART_ALL_FrameworkProgTypeSSA_AchPer = NULL,
			NART_ALL_FrameworkProgTypeSSA_PassPer = NULL,
	'

	SET @SQLString += 
		N'
			NART_GFE_Age_Leave = NRG_AGE.BM_Count_Overall,
			NART_GFE_Age_RetPer = NRG_AGE.BM_RetCount_Overall / 100,
			NART_GFE_Age_AchPer = NRG_AGE.BM_AchCount_Overall / 100,
			NART_GFE_Age_PassPer = NRG_AGE.BM_AchComplete_Overall / 100,
			NART_ALL_Age_Leave = NRA_AGE.BM_Count_Overall,
			NART_ALL_Age_RetPer = NRA_AGE.BM_RetCount_Overall / 100,
			NART_ALL_Age_AchPer = NRA_AGE.BM_AchCount_Overall / 100,
			NART_ALL_Age_PassPer = NRA_AGE.BM_AchComplete_Overall / 100,

			NART_GFE_Sex_Leave = NRG_GEN.BM_Count_Overall,
			NART_GFE_Sex_RetPer = NRG_GEN.BM_RetCount_Overall / 100,
			NART_GFE_Sex_AchPer = NRG_GEN.BM_AchCount_Overall / 100,
			NART_GFE_Sex_PassPer = NRG_GEN.BM_AchComplete_Overall / 100,
			NART_ALL_Sex_Leave = NRA_GEN.BM_Count_Overall,
			NART_ALL_Sex_RetPer = NRA_GEN.BM_RetCount_Overall / 100,
			NART_ALL_Sex_AchPer = NRA_GEN.BM_AchCount_Overall / 100,
			NART_ALL_Sex_PassPer = NRA_GEN.BM_AchComplete_Overall / 100,

			NART_GFE_SexAge_Leave = NRG_GENAGE.BM_Count_Overall,
			NART_GFE_SexAge_RetPer = NRG_GENAGE.BM_RetCount_Overall / 100,
			NART_GFE_SexAge_AchPer = NRG_GENAGE.BM_AchCount_Overall / 100,
			NART_GFE_SexAge_PassPer = NRG_GENAGE.BM_AchComplete_Overall / 100,
			NART_ALL_SexAge_Leave = NRA_GENAGE.BM_Count_Overall,
			NART_ALL_SexAge_RetPer = NRA_GENAGE.BM_RetCount_Overall / 100,
			NART_ALL_SexAge_AchPer = NRA_GENAGE.BM_AchCount_Overall / 100,
			NART_ALL_SexAge_PassPer = NRA_GENAGE.BM_AchComplete_Overall / 100,

            NART_GFE_LevelGroup_Leave = NRG_LEVG.BM_Count_Overall,
			NART_GFE_LevelGroup_RetPer = NRG_LEVG.BM_RetCount_Overall / 100,
			NART_GFE_LevelGroup_AchPer = NRG_LEVG.BM_AchCount_Overall / 100,
			NART_GFE_LevelGroup_PassPer = NRG_LEVG.BM_AchComplete_Overall / 100,
			NART_ALL_LevelGroup_Leave = NRA_LEVG.BM_Count_Overall,
			NART_ALL_LevelGroup_RetPer = NRA_LEVG.BM_RetCount_Overall / 100,
			NART_ALL_LevelGroup_AchPer = NRA_LEVG.BM_AchCount_Overall / 100,
			NART_ALL_LevelGroup_PassPer = NRA_LEVG.BM_AchComplete_Overall / 100,

            NART_GFE_LevelGroupAge_Leave = NRG_LEVGAGE.BM_Count_Overall,
			NART_GFE_LevelGroupAge_RetPer = NRG_LEVGAGE.BM_RetCount_Overall / 100,
			NART_GFE_LevelGroupAge_AchPer = NRG_LEVGAGE.BM_AchCount_Overall / 100,
			NART_GFE_LevelGroupAge_PassPer = NRG_LEVGAGE.BM_AchComplete_Overall / 100,
			NART_ALL_LevelGroupAge_Leave = NRA_LEVGAGE.BM_Count_Overall,
			NART_ALL_LevelGroupAge_RetPer = NRA_LEVGAGE.BM_RetCount_Overall / 100,
			NART_ALL_LevelGroupAge_AchPer = NRA_LEVGAGE.BM_AchCount_Overall / 100,
			NART_ALL_LevelGroupAge_PassPer = NRA_LEVGAGE.BM_AchComplete_Overall / 100,
	'

	SET @SQLString += 
		N'
			NART_GFE_QualType_Leave = NRG_QT.BM_Count_Overall,
			NART_GFE_QualType_RetPer = NRG_QT.BM_RetCount_Overall / 100,
			NART_GFE_QualType_AchPer = NRG_QT.BM_AchCount_Overall / 100,
			NART_GFE_QualType_PassPer = NRG_QT.BM_AchComplete_Overall / 100,
			NART_ALL_QualType_Leave = NRA_QT.BM_Count_Overall,
			NART_ALL_QualType_RetPer = NRA_QT.BM_RetCount_Overall / 100,
			NART_ALL_QualType_AchPer = NRA_QT.BM_AchCount_Overall / 100,
			NART_ALL_QualType_PassPer = NRA_QT.BM_AchComplete_Overall / 100,

			NART_GFE_QualTypeAge_Leave = NRG_QTAGE.BM_Count_Overall,
			NART_GFE_QualTypeAge_RetPer = NRG_QTAGE.BM_RetCount_Overall / 100,
			NART_GFE_QualTypeAge_AchPer = NRG_QTAGE.BM_AchCount_Overall / 100,
			NART_GFE_QualTypeAge_PassPer = NRG_QTAGE.BM_AchComplete_Overall / 100,
			NART_ALL_QualTypeAge_Leave = NRA_QTAGE.BM_Count_Overall,
			NART_ALL_QualTypeAge_RetPer = NRA_QTAGE.BM_RetCount_Overall / 100,
			NART_ALL_QualTypeAge_AchPer = NRA_QTAGE.BM_AchCount_Overall / 100,
			NART_ALL_QualTypeAge_PassPer = NRA_QTAGE.BM_AchComplete_Overall / 100,

			NART_GFE_QualTypeLevelGroup_Leave = NRG_QTLEVG.BM_Count_Overall,
			NART_GFE_QualTypeLevelGroup_RetPer = NRG_QTLEVG.BM_RetCount_Overall / 100,
			NART_GFE_QualTypeLevelGroup_AchPer = NRG_QTLEVG.BM_AchCount_Overall / 100,
			NART_GFE_QualTypeLevelGroup_PassPer = NRG_QTLEVG.BM_AchComplete_Overall / 100,
			NART_ALL_QualTypeLevelGroup_Leave = NRA_QTLEVG.BM_Count_Overall,
			NART_ALL_QualTypeLevelGroup_RetPer = NRA_QTLEVG.BM_RetCount_Overall / 100,
			NART_ALL_QualTypeLevelGroup_AchPer = NRA_QTLEVG.BM_AchCount_Overall / 100,
			NART_ALL_QualTypeLevelGroup_PassPer = NRA_QTLEVG.BM_AchComplete_Overall / 100,

			NART_GFE_QualTypeLevelGroupAge_Leave = NRG_QTLEVGAGE.BM_Count_Overall,
			NART_GFE_QualTypeLevelGroupAge_RetPer = NRG_QTLEVGAGE.BM_RetCount_Overall / 100,
			NART_GFE_QualTypeLevelGroupAge_AchPer = NRG_QTLEVGAGE.BM_AchCount_Overall / 100,
			NART_GFE_QualTypeLevelGroupAge_PassPer = NRG_QTLEVGAGE.BM_AchComplete_Overall / 100,
			NART_ALL_QualTypeLevelGroupAge_Leave = NRA_QTLEVGAGE.BM_Count_Overall,
			NART_ALL_QualTypeLevelGroupAge_RetPer = NRA_QTLEVGAGE.BM_RetCount_Overall / 100,
			NART_ALL_QualTypeLevelGroupAge_AchPer = NRA_QTLEVGAGE.BM_AchCount_Overall / 100,
			NART_ALL_QualTypeLevelGroupAge_PassPer = NRA_QTLEVGAGE.BM_AchComplete_Overall / 100,

			NART_GFE_Ethnicity_Leave = NRG_ETH.BM_Count_Overall,
			NART_GFE_Ethnicity_RetPer = NRG_ETH.BM_RetCount_Overall / 100,
			NART_GFE_Ethnicity_AchPer = NRG_ETH.BM_AchCount_Overall / 100,
			NART_GFE_Ethnicity_PassPer = NRG_ETH.BM_AchComplete_Overall / 100,
			NART_ALL_Ethnicity_Leave = NRA_ETH.BM_Count_Overall,
			NART_ALL_Ethnicity_RetPer = NRA_ETH.BM_RetCount_Overall / 100,
			NART_ALL_Ethnicity_AchPer = NRA_ETH.BM_AchCount_Overall / 100,
			NART_ALL_Ethnicity_PassPer = NRA_ETH.BM_AchComplete_Overall / 100,

            NART_GFE_EthnicityAge_Leave = NRG_ETHAGE.BM_Count_Overall,
			NART_GFE_EthnicityAge_RetPer = NRG_ETHAGE.BM_RetCount_Overall / 100,
			NART_GFE_EthnicityAge_AchPer = NRG_ETHAGE.BM_AchCount_Overall / 100,
			NART_GFE_EthnicityAge_PassPer = NRG_ETHAGE.BM_AchComplete_Overall / 100,
			NART_ALL_EthnicityAge_Leave = NRA_ETHAGE.BM_Count_Overall,
			NART_ALL_EthnicityAge_RetPer = NRA_ETHAGE.BM_RetCount_Overall / 100,
			NART_ALL_EthnicityAge_AchPer = NRA_ETHAGE.BM_AchCount_Overall / 100,
			NART_ALL_EthnicityAge_PassPer = NRA_ETHAGE.BM_AchComplete_Overall / 100,
	'

	SET @SQLString += 
		N'
			NART_GFE_SSA1_Leave = NRG_SSA1.BM_Count_Overall,
			NART_GFE_SSA1_RetPer = NRG_SSA1.BM_RetCount_Overall / 100,
			NART_GFE_SSA1_AchPer = NRG_SSA1.BM_AchCount_Overall / 100,
			NART_GFE_SSA1_PassPer = NRG_SSA1.BM_AchComplete_Overall / 100,
			NART_ALL_SSA1_Leave = NRA_SSA1.BM_Count_Overall,
			NART_ALL_SSA1_RetPer = NRA_SSA1.BM_RetCount_Overall / 100,
			NART_ALL_SSA1_AchPer = NRA_SSA1.BM_AchCount_Overall / 100,
			NART_ALL_SSA1_PassPer = NRA_SSA1.BM_AchComplete_Overall / 100,

			NART_GFE_SSA1Age_Leave = NRG_SSA1AGE.BM_Count_Overall,
			NART_GFE_SSA1Age_RetPer = NRG_SSA1AGE.BM_RetCount_Overall / 100,
			NART_GFE_SSA1Age_AchPer = NRG_SSA1AGE.BM_AchCount_Overall / 100,
			NART_GFE_SSA1Age_PassPer = NRG_SSA1AGE.BM_AchComplete_Overall / 100,
			NART_ALL_SSA1Age_Leave = NRA_SSA1AGE.BM_Count_Overall,
			NART_ALL_SSA1Age_RetPer = NRA_SSA1AGE.BM_RetCount_Overall / 100,
			NART_ALL_SSA1Age_AchPer = NRA_SSA1AGE.BM_AchCount_Overall / 100,
			NART_ALL_SSA1Age_PassPer = NRA_SSA1AGE.BM_AchComplete_Overall / 100,

			NART_GFE_SSA2_Leave = NRG_SSA2.BM_Count_Overall,
			NART_GFE_SSA2_RetPer = NRG_SSA2.BM_RetCount_Overall / 100,
			NART_GFE_SSA2_AchPer = NRG_SSA2.BM_AchCount_Overall / 100,
			NART_GFE_SSA2_PassPer = NRG_SSA2.BM_AchComplete_Overall / 100,
			NART_ALL_SSA2_Leave = NRA_SSA2.BM_Count_Overall,
			NART_ALL_SSA2_RetPer = NRA_SSA2.BM_RetCount_Overall / 100,
			NART_ALL_SSA2_AchPer = NRA_SSA2.BM_AchCount_Overall / 100,
			NART_ALL_SSA2_PassPer = NRA_SSA2.BM_AchComplete_Overall / 100,

			NART_GFE_SSA2Age_Leave = NRG_SSA2AGE.BM_Count_Overall,
			NART_GFE_SSA2Age_RetPer = NRG_SSA2AGE.BM_RetCount_Overall / 100,
			NART_GFE_SSA2Age_AchPer = NRG_SSA2AGE.BM_AchCount_Overall / 100,
			NART_GFE_SSA2Age_PassPer = NRG_SSA2AGE.BM_AchComplete_Overall / 100,
			NART_ALL_SSA2Age_Leave = NRA_SSA2AGE.BM_Count_Overall,
			NART_ALL_SSA2Age_RetPer = NRA_SSA2AGE.BM_RetCount_Overall / 100,
			NART_ALL_SSA2Age_AchPer = NRA_SSA2AGE.BM_AchCount_Overall / 100,
			NART_ALL_SSA2Age_PassPer = NRA_SSA2AGE.BM_AchComplete_Overall / 100,

			NART_GFE_DifDis_Leave = NRG_DIF.BM_Count_Overall,
			NART_GFE_DifDis_RetPer = NRG_DIF.BM_RetCount_Overall / 100,
			NART_GFE_DifDis_AchPer = NRG_DIF.BM_AchCount_Overall / 100,
			NART_GFE_DifDis_PassPer = NRG_DIF.BM_AchComplete_Overall / 100,
			NART_ALL_DifDis_Leave = NRA_DIF.BM_Count_Overall,
			NART_ALL_DifDis_RetPer = NRA_DIF.BM_RetCount_Overall / 100,
			NART_ALL_DifDis_AchPer = NRA_DIF.BM_AchCount_Overall / 100,
			NART_ALL_DifDis_PassPer = NRA_DIF.BM_AchComplete_Overall / 100,

            NART_GFE_DifDisAge_Leave = NRG_DIFAGE.BM_Count_Overall,
			NART_GFE_DifDisAge_RetPer = NRG_DIFAGE.BM_RetCount_Overall / 100,
			NART_GFE_DifDisAge_AchPer = NRG_DIFAGE.BM_AchCount_Overall / 100,
			NART_GFE_DifDisAge_PassPer = NRG_DIFAGE.BM_AchComplete_Overall / 100,
			NART_ALL_DifDisAge_Leave = NRA_DIFAGE.BM_Count_Overall,
			NART_ALL_DifDisAge_RetPer = NRA_DIFAGE.BM_RetCount_Overall / 100,
			NART_ALL_DifDisAge_AchPer = NRA_DIFAGE.BM_AchCount_Overall / 100,
			NART_ALL_DifDisAge_PassPer = NRA_DIFAGE.BM_AchComplete_Overall / 100
	'

    SET @SQLString += 
        N'
		FROM ' + @ProAchieveDatabaseLocation + 'CL_Midpoint CL
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'vCL_MYS_RDS_Seln MYS 
			ON MYS.CL_MidpointID = CL.CL_MidpointID
            AND MYS.PG_ProviderID = CL.PG_ProviderID
            --AND MYS.DefaultSummary = 0
            AND MYS.IsArchived = 0
            --AND MYS.IsQSRSummary = 1
            --AND MYS.RulesApplied = 1
            --AND MYS.IncludeAllAimTypes = 0
            AND MYS.LastAcademicYearID = (
                SELECT 
                    MaxYear = MAX ( MYS2.LastAcademicYearID )
                FROM ' + @ProAchieveDatabaseLocation + 'vCL_MYS_RDS_Seln MYS2
                WHERE
                    MYS2.DefaultSummary = MYS.DefaultSummary
                    AND MYS2.IsArchived = MYS.IsArchived
                    AND MYS2.IsQSRSummary = MYS.IsQSRSummary
                    AND MYS2.RulesApplied = MYS.RulesApplied
                    AND MYS2.IncludeAllAimTypes = MYS.IncludeAllAimTypes
            )
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Student STU
			ON STU.StudentID = CL.PG_StudentID
			AND STU.AcademicYearID = CL.PG_AcademicYearID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PI_LR_Enrolment ENR 
			ON ENR.PG_ProviderID = CL.PG_ProviderID
			AND ENR.PG_AcademicYearID = CL.PG_AcademicYearID
			AND ENR.PG_StudentID = CL.PG_StudentID
			AND ENR.SequenceNo = CL.SequenceNo
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'GN_Aim AIM 
			ON AIM.GN_AimID = CL.PG_AimID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_Ethnicity ETH
			ON ETH.PG_EthnicityID = CL.PG_EthnicityID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicityGroupQAR ETHQ
			ON ETHQ.PG_EthnicityGroupQARID = ETH.PG_EthnicityGroupQARID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroup ETHG
			ON ETHG.PG_EthnicGroupID = CL.PG_EthnicGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroupSimple ETHGS
			ON ETHGS.PG_EthnicGroupSimpleID = ETHG.PG_EthnicGroupSimpleID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'WideningParticipation UPL 
			ON UPL.WideningParticipationID = CL.PG_UpliftID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA1 SSA1 
			ON SSA1.SSA_Tier1_code = CL.PG_SSA1ID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA2 SSA2 
			ON SSA2.SSA_Tier2_code = CL.PG_SSA2ID
	'
    
    SET @SQLString += 
        N'
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearningAimType QT
			ON QT.PG_LearningAimTypeID = CL.PG_QType1ID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_ILRAimType AIMT
			ON AIMT.PG_ILRAimTypeID = CL.PG_ILRAimTypeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_Duration DUR
			ON DUR.PG_DurationID = CL.PG_DurationID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_DurationGroup DURG
			ON DURG.PG_DurationGroupID = CL.PG_DurationGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_DurationType DURT
			ON DURT.PG_DurationTypeID = CL.PG_DurationTypeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_DurationTypeGroup DURTG
			ON DURTG.PG_DurationTypeGroupID = CL.PG_DurationTypeGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_QualSize QS
			ON QS.PG_QualSizeID = CL.PG_QualSizeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PM_MS_ThresholdValue MINS
			ON MINS.PG_QualSizeID = CL.PG_QualSizeID
			AND MINS.ThresholdID = 1
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Completion CMP
			ON CMP.CompletionID = CL.PG_CompletionID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Outcome OC
			ON OC.OutcomeID = CL.PG_OutcomeID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'Minimum_Standards_Group MSTD
			ON MSTD.Minimum_Standards_GroupID = CL.Minimum_Standards_GroupID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_AgeLSC AGE
			ON AGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_Learner_FAM_Pivoted FAM
			ON FAM.PG_StudentID = CL.PG_StudentID
			AND FAM.PG_ProviderID = CL.PG_ProviderID
			AND FAM.PG_AcademicYearID = CL.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnFAMTypeEHC EHC
			ON EHC.PG_LearnFAMTypeEHCID = FAM.PG_LearnFAMTypeEHCID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearningDelivery_FAM_Pivoted FAMLD
			ON FAMLD.PG_StudentID = CL.PG_StudentID
			AND FAMLD.PG_ProviderID = CL.PG_ProviderID
			AND FAMLD.PG_AcademicYearID = CL.PG_AcademicYearID
			AND FAMLD.SequenceNo = CL.SequenceNo
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnDelFAMTypeLSF LSF
			ON LSF.PG_LearnDelFAMTypeLSFID = FAMLD.PG_LearnDelFAMTypeLSFID
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevel LVL
			ON LVL.PG_NVQLevelID = CL.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevelCPR LVLC
			ON LVLC.PG_NVQLevelCPRID = CL.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'NVQLevelGroup LVLG
			ON LVLG.NVQLevelGroupID = LVL.PG_NVQLevelGroupID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeWard PCW
			ON PCW.Postcode = CL.HomePostcode
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeUplift PCU
			ON PCU.POSTCODE = CL.HomePostcode
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure1IY L1 
			ON L1.GN_Structure1IYID = CL.PG_Structure1ID
			AND L1.PG_AcademicYearID = CL.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure2IY L2
			ON L2.GN_Structure2IYID = CL.PG_Structure2ID
			AND L2.PG_AcademicYearID = CL.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure3IY L3
			ON L3.GN_Structure3IYID = CL.PG_Structure3ID
			AND L3.PG_AcademicYearID = CL.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure4IY L4
			ON L4.GN_Structure4IYID = CL.PG_Structure4ID
			AND L4.PG_AcademicYearID = CL.PG_AcademicYearID
		--LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_CourseStructureIY CRS 
		--	ON CRS.PG_CourseID = CL.PG_AggCourseID
		--	AND CRS.PG_AcademicYearID = CL.PG_HybridEndYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_AggCourse CRS 
			ON CRS.PG_AggCourseID = CL.PG_AggCourseID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_MathsEnglish EM
			ON EM.PG_MathsEnglishID = CL.PG_MathsEnglishID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'DifficultyOrDisability DIF
			ON DIF.DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Disability DIS
			ON DIS.DisabilityID = CL.PG_DisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Enrolment_Attendance ATT 
			ON ATT.StudentID = CL.PG_StudentID
			AND ATT.CollegeID = CL.PG_ProviderID
			AND ATT.AcademicYearID = CL.PG_AcademicYearID
			AND ATT.SequenceNo = CL.SequenceNo
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Student_UDF LAC
			ON LAC.StudentID = CL.PG_StudentID
			AND LAC.CollegeID = CL.PG_ProviderID
			AND LAC.AcademicYearID = CL.PG_AcademicYearID
	'

    SET @SQLString += 
        N'
		LEFT JOIN #NARTsQual NRG_AIM
			ON NRG_AIM.PG_HybridEndYearID = @NatRateYear
			AND NRG_AIM.PG_CollegeTypeID = 2 --GFE
			AND NRG_AIM.PG_AgeLSCID IS NULL
			AND NRG_AIM.PG_AimID = CL.PG_AimID
			AND NRG_AIM.PG_MapID IS NULL
		LEFT JOIN #NARTsQual NRA_AIM
			ON NRA_AIM.PG_HybridEndYearID = @NatRateYear
			AND NRA_AIM.PG_CollegeTypeID = 0 --ALL
			AND NRA_AIM.PG_AgeLSCID IS NULL
			AND NRA_AIM.PG_AimID = CL.PG_AimID
			AND NRA_AIM.PG_MapID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN #NARTsQual NRG_AIMAGE
			ON NRG_AIMAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_AIMAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_AIMAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_AIMAGE.PG_AimID = CL.PG_AimID
			AND NRG_AIMAGE.PG_MapID IS NULL
		LEFT JOIN #NARTsQual NRA_AIMAGE
			ON NRA_AIMAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_AIMAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_AIMAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_AIMAGE.PG_AimID = CL.PG_AimID
			AND NRA_AIMAGE.PG_MapID IS NULL
    '
    
	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_YR
			ON NRG_YR.PG_HybridEndYearID = @NatRateYear
			AND NRG_YR.PG_CollegeTypeID = 2 --GFE
			AND NRG_YR.PG_AgeLSCID IS NULL
			AND NRG_YR.PG_NVQLevelGroupID IS NULL
			AND NRG_YR.PG_QualSizeID IS NULL
			AND NRG_YR.PG_SSA1ID IS NULL
			AND NRG_YR.PG_SSA2ID IS NULL
			AND NRG_YR.PG_SexID IS NULL
			AND NRG_YR.PG_EthnicityID IS NULL
			AND NRG_YR.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_YR
			ON NRA_YR.PG_HybridEndYearID = @NatRateYear
			AND NRA_YR.PG_CollegeTypeID = 0 --ALL
			AND NRA_YR.PG_AgeLSCID IS NULL
			AND NRA_YR.PG_NVQLevelGroupID IS NULL
			AND NRA_YR.PG_QualSizeID IS NULL
			AND NRA_YR.PG_SSA1ID IS NULL
			AND NRA_YR.PG_SSA2ID IS NULL
			AND NRA_YR.PG_SexID IS NULL
			AND NRA_YR.PG_EthnicityID IS NULL
			AND NRA_YR.PG_DifficultyOrDisabilityID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_QT
			ON NRG_QT.PG_HybridEndYearID = @NatRateYear
			AND NRG_QT.PG_CollegeTypeID = 2 --GFE
			AND NRG_QT.PG_AgeLSCID IS NULL
			AND NRG_QT.PG_NVQLevelGroupID IS NULL
			AND NRG_QT.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QT.PG_SSA1ID IS NULL
			AND NRG_QT.PG_SSA2ID IS NULL
			AND NRG_QT.PG_SexID IS NULL
			AND NRG_QT.PG_EthnicityID IS NULL
			AND NRG_QT.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_QT
			ON NRA_QT.PG_HybridEndYearID = @NatRateYear
			AND NRA_QT.PG_CollegeTypeID = 0 --ALL
			AND NRA_QT.PG_AgeLSCID IS NULL
			AND NRA_QT.PG_NVQLevelGroupID IS NULL
			AND NRA_QT.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QT.PG_SSA1ID IS NULL
			AND NRA_QT.PG_SSA2ID IS NULL
			AND NRA_QT.PG_SexID IS NULL
			AND NRA_QT.PG_EthnicityID IS NULL
			AND NRA_QT.PG_DifficultyOrDisabilityID IS NULL
	'
    
	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_QTAGE
			ON NRG_QTAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_QTAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_QTAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_QTAGE.PG_NVQLevelGroupID IS NULL
			AND NRG_QTAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTAGE.PG_SSA1ID IS NULL
			AND NRG_QTAGE.PG_SSA2ID IS NULL
			AND NRG_QTAGE.PG_SexID IS NULL
			AND NRG_QTAGE.PG_EthnicityID IS NULL
			AND NRG_QTAGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_QTAGE
			ON NRA_QTAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_QTAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_QTAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_QTAGE.PG_NVQLevelGroupID IS NULL
			AND NRA_QTAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTAGE.PG_SSA1ID IS NULL
			AND NRA_QTAGE.PG_SSA2ID IS NULL
			AND NRA_QTAGE.PG_SexID IS NULL
			AND NRA_QTAGE.PG_EthnicityID IS NULL
			AND NRA_QTAGE.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_QTLEVG
			ON NRG_QTLEVG.PG_HybridEndYearID = @NatRateYear
			AND NRG_QTLEVG.PG_CollegeTypeID = 2 --GFE
			AND NRG_QTLEVG.PG_AgeLSCID IS NULL
			AND NRG_QTLEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRG_QTLEVG.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTLEVG.PG_SSA1ID IS NULL
			AND NRG_QTLEVG.PG_SSA2ID IS NULL
			AND NRG_QTLEVG.PG_SexID IS NULL
			AND NRG_QTLEVG.PG_EthnicityID IS NULL
			AND NRG_QTLEVG.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_QTLEVG
			ON NRA_QTLEVG.PG_HybridEndYearID = @NatRateYear
			AND NRA_QTLEVG.PG_CollegeTypeID = 0 --ALL
			AND NRA_QTLEVG.PG_AgeLSCID IS NULL
			AND NRA_QTLEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRA_QTLEVG.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTLEVG.PG_SSA1ID IS NULL
			AND NRA_QTLEVG.PG_SSA2ID IS NULL
			AND NRA_QTLEVG.PG_SexID IS NULL
			AND NRA_QTLEVG.PG_EthnicityID IS NULL
			AND NRA_QTLEVG.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_QTLEVGAGE
			ON NRG_QTLEVGAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_QTLEVGAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_QTLEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_QTLEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRG_QTLEVGAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTLEVGAGE.PG_SSA1ID IS NULL
			AND NRG_QTLEVGAGE.PG_SSA2ID IS NULL
			AND NRG_QTLEVGAGE.PG_SexID IS NULL
			AND NRG_QTLEVGAGE.PG_EthnicityID IS NULL
			AND NRG_QTLEVGAGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_QTLEVGAGE
			ON NRA_QTLEVGAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_QTLEVGAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_QTLEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_QTLEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRA_QTLEVGAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTLEVGAGE.PG_SSA1ID IS NULL
			AND NRA_QTLEVGAGE.PG_SSA2ID IS NULL
			AND NRA_QTLEVGAGE.PG_SexID IS NULL
			AND NRA_QTLEVGAGE.PG_EthnicityID IS NULL
			AND NRA_QTLEVGAGE.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_AGE
			ON NRG_AGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_AGE.PG_NVQLevelGroupID IS NULL
			AND NRG_AGE.PG_QualSizeID IS NULL
			AND NRG_AGE.PG_SSA1ID IS NULL
			AND NRG_AGE.PG_SSA2ID IS NULL
			AND NRG_AGE.PG_SexID IS NULL
			AND NRG_AGE.PG_EthnicityID IS NULL
			AND NRG_AGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_AGE
			ON NRA_AGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_AGE.PG_NVQLevelGroupID IS NULL
			AND NRA_AGE.PG_QualSizeID IS NULL
			AND NRA_AGE.PG_SSA1ID IS NULL
			AND NRA_AGE.PG_SSA2ID IS NULL
			AND NRA_AGE.PG_SexID IS NULL
			AND NRA_AGE.PG_EthnicityID IS NULL
			AND NRA_AGE.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_GEN
			ON NRG_GEN.PG_HybridEndYearID = @NatRateYear
			AND NRG_GEN.PG_CollegeTypeID = 2 --GFE
			AND NRG_GEN.PG_AgeLSCID IS NULL
			AND NRG_GEN.PG_NVQLevelGroupID IS NULL
			AND NRG_GEN.PG_QualSizeID IS NULL
			AND NRG_GEN.PG_SSA1ID IS NULL
			AND NRG_GEN.PG_SSA2ID IS NULL
			AND NRG_GEN.PG_SexID = CL.PG_SexID
			AND NRG_GEN.PG_EthnicityID IS NULL
			AND NRG_GEN.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_GEN
			ON NRA_GEN.PG_HybridEndYearID = @NatRateYear
			AND NRA_GEN.PG_CollegeTypeID = 0 --ALL
			AND NRA_GEN.PG_AgeLSCID IS NULL
			AND NRA_GEN.PG_NVQLevelGroupID IS NULL
			AND NRA_GEN.PG_QualSizeID IS NULL
			AND NRA_GEN.PG_SSA1ID IS NULL
			AND NRA_GEN.PG_SSA2ID IS NULL
			AND NRA_GEN.PG_SexID = CL.PG_SexID
			AND NRA_GEN.PG_EthnicityID IS NULL
			AND NRA_GEN.PG_DifficultyOrDisabilityID IS NULL
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_GENAGE
			ON NRG_GENAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_GENAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_GENAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_GENAGE.PG_NVQLevelGroupID IS NULL
			AND NRG_GENAGE.PG_QualSizeID IS NULL
			AND NRG_GENAGE.PG_SSA1ID IS NULL
			AND NRG_GENAGE.PG_SSA2ID IS NULL
			AND NRG_GENAGE.PG_SexID = CL.PG_SexID
			AND NRG_GENAGE.PG_EthnicityID IS NULL
			AND NRG_GENAGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_GENAGE
			ON NRA_GENAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_GENAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_GENAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_GENAGE.PG_NVQLevelGroupID IS NULL
			AND NRA_GENAGE.PG_QualSizeID IS NULL
			AND NRA_GENAGE.PG_SSA1ID IS NULL
			AND NRA_GENAGE.PG_SSA2ID IS NULL
			AND NRA_GENAGE.PG_SexID = CL.PG_SexID
			AND NRA_GENAGE.PG_EthnicityID IS NULL
			AND NRA_GENAGE.PG_DifficultyOrDisabilityID IS NULL
	'
    
	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_LEVG
			ON NRG_LEVG.PG_HybridEndYearID = @NatRateYear
			AND NRG_LEVG.PG_CollegeTypeID = 2 --GFE
			AND NRG_LEVG.PG_AgeLSCID IS NULL
			AND NRG_LEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRG_LEVG.PG_QualSizeID IS NULL
			AND NRG_LEVG.PG_SSA1ID IS NULL
			AND NRG_LEVG.PG_SSA2ID IS NULL
			AND NRG_LEVG.PG_SexID IS NULL
			AND NRG_LEVG.PG_EthnicityID IS NULL
			AND NRG_LEVG.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_LEVG
			ON NRA_LEVG.PG_HybridEndYearID = @NatRateYear
			AND NRA_LEVG.PG_CollegeTypeID = 0 --ALL
			AND NRA_LEVG.PG_AgeLSCID IS NULL
			AND NRA_LEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRA_LEVG.PG_QualSizeID IS NULL
			AND NRA_LEVG.PG_SSA1ID IS NULL
			AND NRA_LEVG.PG_SSA2ID IS NULL
			AND NRA_LEVG.PG_SexID IS NULL
			AND NRA_LEVG.PG_EthnicityID IS NULL
			AND NRA_LEVG.PG_DifficultyOrDisabilityID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_LEVGAGE
			ON NRG_LEVGAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_LEVGAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_LEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_LEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRG_LEVGAGE.PG_QualSizeID IS NULL
			AND NRG_LEVGAGE.PG_SSA1ID IS NULL
			AND NRG_LEVGAGE.PG_SSA2ID IS NULL
			AND NRG_LEVGAGE.PG_SexID IS NULL
			AND NRG_LEVGAGE.PG_EthnicityID IS NULL
			AND NRG_LEVGAGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_LEVGAGE
			ON NRA_LEVGAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_LEVGAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_LEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_LEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
			AND NRA_LEVGAGE.PG_QualSizeID IS NULL
			AND NRA_LEVGAGE.PG_SSA1ID IS NULL
			AND NRA_LEVGAGE.PG_SSA2ID IS NULL
			AND NRA_LEVGAGE.PG_SexID IS NULL
			AND NRA_LEVGAGE.PG_EthnicityID IS NULL
			AND NRA_LEVGAGE.PG_DifficultyOrDisabilityID IS NULL
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_ETH
			ON NRG_ETH.PG_HybridEndYearID = @NatRateYear
			AND NRG_ETH.PG_CollegeTypeID = 2 --GFE
			AND NRG_ETH.PG_AgeLSCID IS NULL
			AND NRG_ETH.PG_NVQLevelGroupID IS NULL
			AND NRG_ETH.PG_QualSizeID IS NULL
			AND NRG_ETH.PG_SSA1ID IS NULL
			AND NRG_ETH.PG_SSA2ID IS NULL
			AND NRG_ETH.PG_SexID IS NULL
			AND NRG_ETH.PG_EthnicityID = CL.PG_EthnicityID
			AND NRG_ETH.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_ETH
			ON NRA_ETH.PG_HybridEndYearID = @NatRateYear
			AND NRA_ETH.PG_CollegeTypeID = 0 --ALL
			AND NRA_ETH.PG_AgeLSCID IS NULL
			AND NRA_ETH.PG_NVQLevelGroupID IS NULL
			AND NRA_ETH.PG_QualSizeID IS NULL
			AND NRA_ETH.PG_SSA1ID IS NULL
			AND NRA_ETH.PG_SSA2ID IS NULL
			AND NRA_ETH.PG_SexID IS NULL
			AND NRA_ETH.PG_EthnicityID = CL.PG_EthnicityID
			AND NRA_ETH.PG_DifficultyOrDisabilityID IS NULL
	'
    
	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_ETHAGE
			ON NRG_ETHAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_ETHAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_ETHAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_ETHAGE.PG_NVQLevelGroupID IS NULL
			AND NRG_ETHAGE.PG_QualSizeID IS NULL
			AND NRG_ETHAGE.PG_SSA1ID IS NULL
			AND NRG_ETHAGE.PG_SSA2ID IS NULL
			AND NRG_ETHAGE.PG_SexID IS NULL
			AND NRG_ETHAGE.PG_EthnicityID = CL.PG_EthnicityID
			AND NRG_ETHAGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_ETHAGE
			ON NRA_ETHAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_ETHAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_ETHAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_ETHAGE.PG_NVQLevelGroupID IS NULL
			AND NRA_ETHAGE.PG_QualSizeID IS NULL
			AND NRA_ETHAGE.PG_SSA1ID IS NULL
			AND NRA_ETHAGE.PG_SSA2ID IS NULL
			AND NRA_ETHAGE.PG_SexID IS NULL
			AND NRA_ETHAGE.PG_EthnicityID = CL.PG_EthnicityID
			AND NRA_ETHAGE.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_SSA1
			ON NRG_SSA1.PG_HybridEndYearID = @NatRateYear
			AND NRG_SSA1.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA1.PG_AgeLSCID IS NULL
			AND NRG_SSA1.PG_NVQLevelGroupID IS NULL
			AND NRG_SSA1.PG_QualSizeID IS NULL
			AND NRG_SSA1.PG_SSA1ID = CL.PG_SSA1ID
			AND NRG_SSA1.PG_SSA2ID IS NULL
			AND NRG_SSA1.PG_SexID IS NULL
			AND NRG_SSA1.PG_EthnicityID IS NULL
			AND NRG_SSA1.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_SSA1
			ON NRA_SSA1.PG_HybridEndYearID = @NatRateYear
			AND NRA_SSA1.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA1.PG_AgeLSCID IS NULL
			AND NRA_SSA1.PG_NVQLevelGroupID IS NULL
			AND NRA_SSA1.PG_QualSizeID IS NULL
			AND NRA_SSA1.PG_SSA1ID = CL.PG_SSA1ID
			AND NRA_SSA1.PG_SSA2ID IS NULL
			AND NRA_SSA1.PG_SexID IS NULL
			AND NRA_SSA1.PG_EthnicityID IS NULL
			AND NRA_SSA1.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_SSA1AGE
			ON NRG_SSA1AGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_SSA1AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA1AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_SSA1AGE.PG_NVQLevelGroupID IS NULL
			AND NRG_SSA1AGE.PG_QualSizeID IS NULL
			AND NRG_SSA1AGE.PG_SSA1ID = CL.PG_SSA1ID
			AND NRG_SSA1AGE.PG_SSA2ID IS NULL
			AND NRG_SSA1AGE.PG_SexID IS NULL
			AND NRG_SSA1AGE.PG_EthnicityID IS NULL
			AND NRG_SSA1AGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_SSA1AGE
			ON NRA_SSA1AGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_SSA1AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA1AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_SSA1AGE.PG_NVQLevelGroupID IS NULL
			AND NRA_SSA1AGE.PG_QualSizeID IS NULL
			AND NRA_SSA1AGE.PG_SSA1ID = CL.PG_SSA1ID
			AND NRA_SSA1AGE.PG_SSA2ID IS NULL
			AND NRA_SSA1AGE.PG_SexID IS NULL
			AND NRA_SSA1AGE.PG_EthnicityID IS NULL
			AND NRA_SSA1AGE.PG_DifficultyOrDisabilityID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_SSA2
			ON NRG_SSA2.PG_HybridEndYearID = @NatRateYear
			AND NRG_SSA2.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA2.PG_AgeLSCID IS NULL
			AND NRG_SSA2.PG_NVQLevelGroupID IS NULL
			AND NRG_SSA2.PG_QualSizeID IS NULL
			AND NRG_SSA2.PG_SSA1ID IS NULL
			AND NRG_SSA2.PG_SSA2ID = CL.PG_SSA2ID
			AND NRG_SSA2.PG_SexID IS NULL
			AND NRG_SSA2.PG_EthnicityID IS NULL
			AND NRG_SSA2.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_SSA2
			ON NRA_SSA2.PG_HybridEndYearID = @NatRateYear
			AND NRA_SSA2.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA2.PG_AgeLSCID IS NULL
			AND NRA_SSA2.PG_NVQLevelGroupID IS NULL
			AND NRA_SSA2.PG_QualSizeID IS NULL
			AND NRA_SSA2.PG_SSA1ID IS NULL
			AND NRA_SSA2.PG_SSA2ID = CL.PG_SSA2ID
			AND NRA_SSA2.PG_SexID IS NULL
			AND NRA_SSA2.PG_EthnicityID IS NULL
			AND NRA_SSA2.PG_DifficultyOrDisabilityID IS NULL
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_SSA2AGE
			ON NRG_SSA2AGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_SSA2AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA2AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_SSA2AGE.PG_NVQLevelGroupID IS NULL
			AND NRG_SSA2AGE.PG_QualSizeID IS NULL
			AND NRG_SSA2AGE.PG_SSA1ID IS NULL
			AND NRG_SSA2AGE.PG_SSA2ID = CL.PG_SSA2ID
			AND NRG_SSA2AGE.PG_SexID IS NULL
			AND NRG_SSA2AGE.PG_EthnicityID IS NULL
			AND NRG_SSA2AGE.PG_DifficultyOrDisabilityID IS NULL
		LEFT JOIN #NARTs NRA_SSA2AGE
			ON NRA_SSA2AGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_SSA2AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA2AGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_SSA2AGE.PG_NVQLevelGroupID IS NULL
			AND NRA_SSA2AGE.PG_QualSizeID IS NULL
			AND NRA_SSA2AGE.PG_SSA1ID IS NULL
			AND NRA_SSA2AGE.PG_SSA2ID = CL.PG_SSA2ID
			AND NRA_SSA2AGE.PG_SexID IS NULL
			AND NRA_SSA2AGE.PG_EthnicityID IS NULL
			AND NRA_SSA2AGE.PG_DifficultyOrDisabilityID IS NULL
	'
    
	SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_DIF
			ON NRG_DIF.PG_HybridEndYearID = @NatRateYear
			AND NRG_DIF.PG_CollegeTypeID = 2 --GFE
			AND NRG_DIF.PG_AgeLSCID IS NULL
			AND NRG_DIF.PG_NVQLevelGroupID IS NULL
			AND NRG_DIF.PG_QualSizeID IS NULL
			AND NRG_DIF.PG_SSA1ID IS NULL
			AND NRG_DIF.PG_SSA2ID IS NULL
			AND NRG_DIF.PG_SexID IS NULL
			AND NRG_DIF.PG_EthnicityID IS NULL
			AND NRG_DIF.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
		LEFT JOIN #NARTs NRA_DIF
			ON NRA_DIF.PG_HybridEndYearID = @NatRateYear
			AND NRA_DIF.PG_CollegeTypeID = 0 --ALL
			AND NRA_DIF.PG_AgeLSCID IS NULL
			AND NRA_DIF.PG_NVQLevelGroupID IS NULL
			AND NRA_DIF.PG_QualSizeID IS NULL
			AND NRA_DIF.PG_SSA1ID IS NULL
			AND NRA_DIF.PG_SSA2ID IS NULL
			AND NRA_DIF.PG_SexID IS NULL
			AND NRA_DIF.PG_EthnicityID IS NULL
			AND NRA_DIF.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN #NARTs NRG_DIFAGE
			ON NRG_DIFAGE.PG_HybridEndYearID = @NatRateYear
			AND NRG_DIFAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_DIFAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_DIFAGE.PG_NVQLevelGroupID IS NULL
			AND NRG_DIFAGE.PG_QualSizeID IS NULL
			AND NRG_DIFAGE.PG_SSA1ID IS NULL
			AND NRG_DIFAGE.PG_SSA2ID IS NULL
			AND NRG_DIFAGE.PG_SexID IS NULL
			AND NRG_DIFAGE.PG_EthnicityID IS NULL
			AND NRG_DIFAGE.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
		LEFT JOIN #NARTs NRA_DIFAGE
			ON NRA_DIFAGE.PG_HybridEndYearID = @NatRateYear
			AND NRA_DIFAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_DIFAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_DIFAGE.PG_NVQLevelGroupID IS NULL
			AND NRA_DIFAGE.PG_QualSizeID IS NULL
			AND NRA_DIFAGE.PG_SSA1ID IS NULL
			AND NRA_DIFAGE.PG_SSA2ID IS NULL
			AND NRA_DIFAGE.PG_SexID IS NULL
			AND NRA_DIFAGE.PG_EthnicityID IS NULL
			AND NRA_DIFAGE.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
	'
    
    SET @SQLString += 
        N'
		WHERE 
			CL.PG_HybridEndYearID = @AcademicYear
			--AND MYS.LastAcademicYearID = @AcademicYear
	'

	--SELECT @SQLString AS [processing-instruction(x)] FOR XML PATH('')

	SET @SQLParams = 
        N'@ProviderRef NVARCHAR(50),
		@AcademicYear NVARCHAR(5),
		@OutputTableLocation NVARCHAR(200),
		@UserDefinedTrueValue NVARCHAR(50),
		@ALSStudentUserDefinedField INT,
		@LookedAfterStudentUserDefinedField INT,
		@CareLeaverStudentUserDefinedField INT,
		@YoungCarerStudentUserDefinedField INT,
		@YoungParentStudentUserDefinedField INT,
		@GroupCodeEnrolmentUserDefinedField INT';

    EXECUTE sp_executesql 
        @SQLString, 
        @SQLParams, 
		@ProviderRef = @ProviderRef,
        @AcademicYear = @AcademicYear, 
		@OutputTableLocation = @OutputTableLocation,
		@UserDefinedTrueValue = @UserDefinedTrueValue,
		@ALSStudentUserDefinedField = @ALSStudentUserDefinedField,
		@LookedAfterStudentUserDefinedField = @LookedAfterStudentUserDefinedField,
		@CareLeaverStudentUserDefinedField = @CareLeaverStudentUserDefinedField,
		@YoungCarerStudentUserDefinedField = @YoungCarerStudentUserDefinedField,
		@YoungParentStudentUserDefinedField = @YoungParentStudentUserDefinedField,
		@GroupCodeEnrolmentUserDefinedField = @GroupCodeEnrolmentUserDefinedField

	SET @NumRowsChanged = @@ROWCOUNT
	SET @ErrorCode = @@ERROR
END