CREATE OR ALTER PROCEDURE SPR_PRA_ProAchieveSummaryData_CLTimely
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
					WHEN @AcademicYear >= MAX ( NR.PG_ExpEndYrID ) THEN MAX ( NR.PG_ExpEndYrID )
					ELSE @AcademicYear
				END
		FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Timely NR

		
		INSERT INTO ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData WITH (TABLOCKX)
		SELECT
			EndYear = CL.PG_ExpEndYrID,
			AcademicYear = CL.PG_AcademicYearID,
			StartYear = CL.StartYear,
			ProvisionType = ''CL'',
			SummaryType = ''Timely'',
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
			IsStart = CL.CLStartTimely,
			IsLeaver = CL.P_Count_TimelyQSRExclude,
			IsLeaverBestCase = CL.P_Count_Timely_BestCase,
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
			IsCont = CL.PVCont,
			IsWdr = CASE WHEN CL.IsWithdrawnAll = ''Y'' THEN 1 ELSE 0 END,
			IsWdrInQualifyingPeriod = CASE WHEN CL.IsWithdrawnInQualPeriod = ''Y'' THEN 1 ELSE 0 END,
			IsWdrAfterQualifyingPeriod = CASE WHEN CL.IsWithdrawnAfterQualPeriod = ''Y'' THEN 1 ELSE 0 END,
			IsPlannedBreak = CL.P_Plan_Break_Timely,
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
			IsComp = CL.P_Complete_TimelyQSRExclude,
			IsRetInYr = CL.PVCont + CL.PVCompV + CL.P_CompUnknown,
			IsRet = CL.PVCont + CL.PVCompV + CL.P_CompUnknown,
			IsAch = CL.P_Ach_TimelyQSRExclude,
			IsAchBestCase = CL.P_Ach_Timely_BestCase,
			IsPassHigh = CL.PVHigh,
			IsPassAToC = CL.CLPassRateAC_Timely,
			FrameworkStatusCode = NULL,
			FrameworkStatusName = NULL,
			IsCompAwaitAch = CL.P_CompUnknown,
	'

    SET @SQLString += 
        N'
			NART_GFE_Overall_Leave = NRG_YR.Leave,
			NART_GFE_Overall_RetPer = NRG_YR.RetPer,
			NART_GFE_Overall_AchPer = NRG_YR.AchPer,
			NART_GFE_Overall_PassPer = NRG_YR.PassPer,
			NART_ALL_Overall_Leave = NRA_YR.Leave,
			NART_ALL_Overall_RetPer = NRA_YR.RetPer,
			NART_ALL_Overall_AchPer = NRA_YR.AchPer,
			NART_ALL_Overall_PassPer = NRA_YR.PassPer,

			NART_GFE_Aim_Leave = NRG_AIM.BM_Count_Timely,
			NART_GFE_Aim_Comp = NULL,
			NART_GFE_Aim_RetPer = NULL,
			NART_GFE_Aim_Ach = ROUND ( ( CAST ( NRG_AIM.BM_Count_Timely AS FLOAT ) / 100 ) * NRG_AIM.BM_AchCount_Timely, 0 ),
			NART_GFE_Aim_AchPer = NRG_AIM.BM_AchCount_Timely / 100,
			NART_GFE_Aim_Pass = NULL,
			NART_GFE_Aim_PassPer = NULL,
			NART_ALL_Aim_Leave = NRA_AIM.BM_Count_Timely,
			NART_ALL_Aim_Comp = NULL,
			NART_ALL_Aim_RetPer = NULL,
			NART_ALL_Aim_Ach = ROUND ( ( CAST ( NRA_AIM.BM_Count_Timely AS FLOAT ) / 100 ) * NRA_AIM.BM_AchCount_Timely, 0 ),
			NART_ALL_Aim_AchPer = NRA_AIM.BM_AchCount_Timely / 100,
			NART_ALL_Aim_Pass = NULL,
			NART_ALL_Aim_PassPer = NULL,

			NART_GFE_Aim_Leave = NRG_AIMAGE.BM_Count_Timely,
			NART_GFE_Aim_Comp = NULL,
			NART_GFE_Aim_RetPer = NULL,
			NART_GFE_Aim_Ach = ROUND ( ( CAST ( NRG_AIMAGE.BM_Count_Timely AS FLOAT ) / 100 ) * NRG_AIMAGE.BM_AchCount_Timely, 0 ),
			NART_GFE_Aim_AchPer = NRG_AIMAGE.BM_AchCount_Timely / 100,
			NART_GFE_Aim_Pass = NULL,
			NART_GFE_Aim_PassPer = NULL,
			NART_ALL_Aim_Leave = NRA_AIMAGE.BM_Count_Timely,
			NART_ALL_Aim_Comp = NULL,
			NART_ALL_Aim_RetPer = NULL,
			NART_ALL_Aim_Ach = ROUND ( ( CAST ( NRA_AIMAGE.BM_Count_Timely AS FLOAT ) / 100 ) * NRA_AIMAGE.BM_AchCount_Timely, 0 ),
			NART_ALL_Aim_AchPer = NRA_AIMAGE.BM_AchCount_Timely / 100,
			NART_ALL_Aim_Pass = NULL,
			NART_ALL_Aim_PassPer = NULL,

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
			NART_GFE_Age_Leave = NRG_AGE.Leave,
			NART_GFE_Age_RetPer = NRG_AGE.RetPer,
			NART_GFE_Age_AchPer = NRG_AGE.AchPer,
			NART_GFE_Age_PassPer = NRG_AGE.PassPer,
			NART_ALL_Age_Leave = NRA_AGE.Leave,
			NART_ALL_Age_RetPer = NRA_AGE.RetPer,
			NART_ALL_Age_AchPer = NRA_AGE.AchPer,
			NART_ALL_Age_PassPer = NRA_AGE.PassPer,

			NART_GFE_Sex_Leave = NRG_GEN.Leave,
			NART_GFE_Sex_RetPer = NRG_GEN.RetPer,
			NART_GFE_Sex_AchPer = NRG_GEN.AchPer,
			NART_GFE_Sex_PassPer = NRG_GEN.PassPer,
			NART_ALL_Sex_Leave = NRA_GEN.Leave,
			NART_ALL_Sex_RetPer = NRA_GEN.RetPer,
			NART_ALL_Sex_AchPer = NRA_GEN.AchPer,
			NART_ALL_Sex_PassPer = NRA_GEN.PassPer,

			NART_GFE_SexAge_Leave = NRG_GENAGE.Leave,
			NART_GFE_SexAge_RetPer = NRG_GENAGE.RetPer,
			NART_GFE_SexAge_AchPer = NRG_GENAGE.AchPer,
			NART_GFE_SexAge_PassPer = NRG_GENAGE.PassPer,
			NART_ALL_SexAge_Leave = NRA_GENAGE.Leave,
			NART_ALL_SexAge_RetPer = NRA_GENAGE.RetPer,
			NART_ALL_SexAge_AchPer = NRA_GENAGE.AchPer,
			NART_ALL_SexAge_PassPer = NRA_GENAGE.PassPer,


			NART_GFE_Level_Leave = NRG_LEV.Leave,
			NART_GFE_Level_RetPer = NRG_LEV.RetPer,
			NART_GFE_Level_AchPer = NRG_LEV.AchPer,
			NART_GFE_Level_PassPer = NRG_LEV.PassPer,
			NART_ALL_Level_Leave = NRA_LEV.Leave,
			NART_ALL_Level_RetPer = NRA_LEV.RetPer,
			NART_ALL_Level_AchPer = NRA_LEV.AchPer,
			NART_ALL_Level_PassPer = NRA_LEV.PassPer,

            NART_GFE_LevelAge_Leave = NRG_LEVAGE.Leave,
			NART_GFE_LevelAge_RetPer = NRG_LEVAGE.RetPer,
			NART_GFE_LevelAge_AchPer = NRG_LEVAGE.AchPer,
			NART_GFE_LevelAge_PassPer = NRG_LEVAGE.PassPer,
			NART_ALL_LevelAge_Leave = NRA_LEVAGE.Leave,
			NART_ALL_LevelAge_RetPer = NRA_LEVAGE.RetPer,
			NART_ALL_LevelAge_AchPer = NRA_LEVAGE.AchPer,
			NART_ALL_LevelAge_PassPer = NRA_LEVAGE.PassPer,

            NART_GFE_LevelGroup_Leave = NRG_LEVG.Leave,
			NART_GFE_LevelGroup_RetPer = NRG_LEVG.RetPer,
			NART_GFE_LevelGroup_AchPer = NRG_LEVG.AchPer,
			NART_GFE_LevelGroup_PassPer = NRG_LEVG.PassPer,
			NART_ALL_LevelGroup_Leave = NRA_LEVG.Leave,
			NART_ALL_LevelGroup_RetPer = NRA_LEVG.RetPer,
			NART_ALL_LevelGroup_AchPer = NRA_LEVG.AchPer,
			NART_ALL_LevelGroup_PassPer = NRA_LEVG.PassPer,

            NART_GFE_LevelGroupAge_Leave = NRG_LEVGAGE.Leave,
			NART_GFE_LevelGroupAge_RetPer = NRG_LEVGAGE.RetPer,
			NART_GFE_LevelGroupAge_AchPer = NRG_LEVGAGE.AchPer,
			NART_GFE_LevelGroupAge_PassPer = NRG_LEVGAGE.PassPer,
			NART_ALL_LevelGroupAge_Leave = NRA_LEVGAGE.Leave,
			NART_ALL_LevelGroupAge_RetPer = NRA_LEVGAGE.RetPer,
			NART_ALL_LevelGroupAge_AchPer = NRA_LEVGAGE.AchPer,
			NART_ALL_LevelGroupAge_PassPer = NRA_LEVGAGE.PassPer,
	'

	SET @SQLString += 
		N'
			NART_GFE_QualType_Leave = NRG_QT.Leave,
			NART_GFE_QualType_RetPer = NRG_QT.RetPer,
			NART_GFE_QualType_AchPer = NRG_QT.AchPer,
			NART_GFE_QualType_PassPer = NRG_QT.PassPer,
			NART_ALL_QualType_Leave = NRA_QT.Leave,
			NART_ALL_QualType_RetPer = NRA_QT.RetPer,
			NART_ALL_QualType_AchPer = NRA_QT.AchPer,
			NART_ALL_QualType_PassPer = NRA_QT.PassPer,

			NART_GFE_QualTypeAge_Leave = NRG_QTAGE.Leave,
			NART_GFE_QualTypeAge_RetPer = NRG_QTAGE.RetPer,
			NART_GFE_QualTypeAge_AchPer = NRG_QTAGE.AchPer,
			NART_GFE_QualTypeAge_PassPer = NRG_QTAGE.PassPer,
			NART_ALL_QualTypeAge_Leave = NRA_QTAGE.Leave,
			NART_ALL_QualTypeAge_RetPer = NRA_QTAGE.RetPer,
			NART_ALL_QualTypeAge_AchPer = NRA_QTAGE.AchPer,
			NART_ALL_QualTypeAge_PassPer = NRA_QTAGE.PassPer,

			NART_GFE_QualTypeLevelGroup_Leave = NRG_QTLEVG.Leave,
			NART_GFE_QualTypeLevelGroup_RetPer = NRG_QTLEVG.RetPer,
			NART_GFE_QualTypeLevelGroup_AchPer = NRG_QTLEVG.AchPer,
			NART_GFE_QualTypeLevelGroup_PassPer = NRG_QTLEVG.PassPer,
			NART_ALL_QualTypeLevelGroup_Leave = NRA_QTLEVG.Leave,
			NART_ALL_QualTypeLevelGroup_RetPer = NRA_QTLEVG.RetPer,
			NART_ALL_QualTypeLevelGroup_AchPer = NRA_QTLEVG.AchPer,
			NART_ALL_QualTypeLevelGroup_PassPer = NRA_QTLEVG.PassPer,

			NART_GFE_QualTypeLevelGroupAge_Leave = NRG_QTLEVGAGE.Leave,
			NART_GFE_QualTypeLevelGroupAge_RetPer = NRG_QTLEVGAGE.RetPer,
			NART_GFE_QualTypeLevelGroupAge_AchPer = NRG_QTLEVGAGE.AchPer,
			NART_GFE_QualTypeLevelGroupAge_PassPer = NRG_QTLEVGAGE.PassPer,
			NART_ALL_QualTypeLevelGroupAge_Leave = NRA_QTLEVGAGE.Leave,
			NART_ALL_QualTypeLevelGroupAge_RetPer = NRA_QTLEVGAGE.RetPer,
			NART_ALL_QualTypeLevelGroupAge_AchPer = NRA_QTLEVGAGE.AchPer,
			NART_ALL_QualTypeLevelGroupAge_PassPer = NRA_QTLEVGAGE.PassPer,

			NART_GFE_Ethnicity_Leave = NRG_ETH.Leave,
			NART_GFE_Ethnicity_RetPer = NRG_ETH.RetPer,
			NART_GFE_Ethnicity_AchPer = NRG_ETH.AchPer,
			NART_GFE_Ethnicity_PassPer = NRG_ETH.PassPer,
			NART_ALL_Ethnicity_Leave = NRA_ETH.Leave,
			NART_ALL_Ethnicity_RetPer = NRA_ETH.RetPer,
			NART_ALL_Ethnicity_AchPer = NRA_ETH.AchPer,
			NART_ALL_Ethnicity_PassPer = NRA_ETH.PassPer,

            NART_GFE_EthnicityAge_Leave = NRG_ETHAGE.Leave,
			NART_GFE_EthnicityAge_RetPer = NRG_ETHAGE.RetPer,
			NART_GFE_EthnicityAge_AchPer = NRG_ETHAGE.AchPer,
			NART_GFE_EthnicityAge_PassPer = NRG_ETHAGE.PassPer,
			NART_ALL_EthnicityAge_Leave = NRA_ETHAGE.Leave,
			NART_ALL_EthnicityAge_RetPer = NRA_ETHAGE.RetPer,
			NART_ALL_EthnicityAge_AchPer = NRA_ETHAGE.AchPer,
			NART_ALL_EthnicityAge_PassPer = NRA_ETHAGE.PassPer,

			NART_GFE_EthnicGroup_Leave = NRG_ETHG.Leave,
			NART_GFE_EthnicGroup_RetPer = NRG_ETHG.RetPer,
			NART_GFE_EthnicGroup_AchPer = NRG_ETHG.AchPer,
			NART_GFE_EthnicGroup_PassPer = NRG_ETHG.PassPer,
			NART_ALL_EthnicGroup_Leave = NRA_ETHG.Leave,
			NART_ALL_EthnicGroup_RetPer = NRA_ETHG.RetPer,
			NART_ALL_EthnicGroup_AchPer = NRA_ETHG.AchPer,
			NART_ALL_EthnicGroup_PassPer = NRA_ETHG.PassPer,

            NART_GFE_EthnicGroupAge_Leave = NRG_ETHGAGE.Leave,
			NART_GFE_EthnicGroupAge_RetPer = NRG_ETHGAGE.RetPer,
			NART_GFE_EthnicGroupAge_AchPer = NRG_ETHGAGE.AchPer,
			NART_GFE_EthnicGroupAge_PassPer = NRG_ETHGAGE.PassPer,
			NART_ALL_EthnicGroupAge_Leave = NRA_ETHGAGE.Leave,
			NART_ALL_EthnicGroupAge_RetPer = NRA_ETHGAGE.RetPer,
			NART_ALL_EthnicGroupAge_AchPer = NRA_ETHGAGE.AchPer,
			NART_ALL_EthnicGroupAge_PassPer = NRA_ETHGAGE.PassPer,
	'

	SET @SQLString += 
		N'
			NART_GFE_SSA1_Leave = NRG_SSA1.Leave,
			NART_GFE_SSA1_RetPer = NRG_SSA1.RetPer,
			NART_GFE_SSA1_AchPer = NRG_SSA1.AchPer,
			NART_GFE_SSA1_PassPer = NRG_SSA1.PassPer,
			NART_ALL_SSA1_Leave = NRA_SSA1.Leave,
			NART_ALL_SSA1_RetPer = NRA_SSA1.RetPer,
			NART_ALL_SSA1_AchPer = NRA_SSA1.AchPer,
			NART_ALL_SSA1_PassPer = NRA_SSA1.PassPer,

			NART_GFE_SSA1Age_Leave = NRG_SSA1AGE.Leave,
			NART_GFE_SSA1Age_RetPer = NRG_SSA1AGE.RetPer,
			NART_GFE_SSA1Age_AchPer = NRG_SSA1AGE.AchPer,
			NART_GFE_SSA1Age_PassPer = NRG_SSA1AGE.PassPer,
			NART_ALL_SSA1Age_Leave = NRA_SSA1AGE.Leave,
			NART_ALL_SSA1Age_RetPer = NRA_SSA1AGE.RetPer,
			NART_ALL_SSA1Age_AchPer = NRA_SSA1AGE.AchPer,
			NART_ALL_SSA1Age_PassPer = NRA_SSA1AGE.PassPer,

			NART_GFE_SSA2_Leave = NRG_SSA2.Leave,
			NART_GFE_SSA2_RetPer = NRG_SSA2.RetPer,
			NART_GFE_SSA2_AchPer = NRG_SSA2.AchPer,
			NART_GFE_SSA2_PassPer = NRG_SSA2.PassPer,
			NART_ALL_SSA2_Leave = NRA_SSA2.Leave,
			NART_ALL_SSA2_RetPer = NRA_SSA2.RetPer,
			NART_ALL_SSA2_AchPer = NRA_SSA2.AchPer,
			NART_ALL_SSA2_PassPer = NRA_SSA2.PassPer,

			NART_GFE_SSA2Age_Leave = NRG_SSA2AGE.Leave,
			NART_GFE_SSA2Age_RetPer = NRG_SSA2AGE.RetPer,
			NART_GFE_SSA2Age_AchPer = NRG_SSA2AGE.AchPer,
			NART_GFE_SSA2Age_PassPer = NRG_SSA2AGE.PassPer,
			NART_ALL_SSA2Age_Leave = NRA_SSA2AGE.Leave,
			NART_ALL_SSA2Age_RetPer = NRA_SSA2AGE.RetPer,
			NART_ALL_SSA2Age_AchPer = NRA_SSA2AGE.AchPer,
			NART_ALL_SSA2Age_PassPer = NRA_SSA2AGE.PassPer,

			NART_GFE_DifDis_Leave = NRG_DIF.Leave,
			NART_GFE_DifDis_RetPer = NRG_DIF.RetPer,
			NART_GFE_DifDis_AchPer = NRG_DIF.AchPer,
			NART_GFE_DifDis_PassPer = NRG_DIF.PassPer,
			NART_ALL_DifDis_Leave = NRA_DIF.Leave,
			NART_ALL_DifDis_RetPer = NRA_DIF.RetPer,
			NART_ALL_DifDis_AchPer = NRA_DIF.AchPer,
			NART_ALL_DifDis_PassPer = NRA_DIF.PassPer,

            NART_GFE_DifDisAge_Leave = NRG_DIFAGE.Leave,
			NART_GFE_DifDisAge_RetPer = NRG_DIFAGE.RetPer,
			NART_GFE_DifDisAge_AchPer = NRG_DIFAGE.AchPer,
			NART_GFE_DifDisAge_PassPer = NRG_DIFAGE.PassPer,

			NART_ALL_DifDisAge_Leave = NRA_DIFAGE.Leave,
			NART_ALL_DifDisAge_RetPer = NRA_DIFAGE.RetPer,
			NART_ALL_DifDisAge_AchPer = NRA_DIFAGE.AchPer,
			NART_ALL_DifDisAge_PassPer = NRA_DIFAGE.PassPer
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
		--	AND CRS.PG_AcademicYearID = CL.PG_ExpEndYrID
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
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_YR
			ON NRG_YR.PG_ExpEndYrID = @NatRateYear
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_YR
			ON NRA_YR.PG_ExpEndYrID = @NatRateYear
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Timely NRG_AIM
			ON NRG_AIM.PG_ExpEndYrID = @NatRateYear
			AND NRG_AIM.PG_CollegeTypeID = 2 --GFE
			AND NRG_AIM.PG_AimID = CL.PG_AimID
			AND NRG_AIM.PG_MapID IS NULL
			AND NRG_AIM.PG_AgeLSCID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Timely NRA_AIM
			ON NRA_AIM.PG_ExpEndYrID = @NatRateYear
			AND NRA_AIM.PG_CollegeTypeID = 0 --ALL
			AND NRA_AIM.PG_AimID = CL.PG_AimID
			AND NRA_AIM.PG_MapID IS NULL
			AND NRA_AIM.PG_AgeLSCID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Timely NRG_AIMAGE
			ON NRG_AIMAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_AIMAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_AIMAGE.PG_AimID = CL.PG_AimID
			AND NRG_AIMAGE.PG_MapID IS NULL
			AND NRG_AIMAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Timely NRA_AIMAGE
			ON NRA_AIMAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_AIMAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_AIMAGE.PG_AimID = CL.PG_AimID
			AND NRA_AIMAGE.PG_MapID IS NULL
			AND NRA_AIMAGE.PG_AgeLSCID = CL.PG_AgeLSCID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_QT
			ON NRG_QT.PG_ExpEndYrID = @NatRateYear
			AND NRG_QT.PG_QualSizeID = CL.PG_QualSizeID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_QT
			ON NRA_QT.PG_ExpEndYrID = @NatRateYear
			AND NRA_QT.PG_QualSizeID = CL.PG_QualSizeID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_QTAGE
			ON NRG_QTAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_QTAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_QTAGE
			ON NRA_QTAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_QTAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

	SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_QTLEVG
			ON NRG_QTLEVG.PG_ExpEndYrID = @NatRateYear
			AND NRG_QTLEVG.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTLEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_QTLEVG
			ON NRA_QTLEVG.PG_ExpEndYrID = @NatRateYear
			AND NRA_QTLEVG.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTLEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
	'

	SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_QTLEVGAGE
			ON NRG_QTLEVGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_QTLEVGAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRG_QTLEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_QTLEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_QTLEVGAGE
			ON NRA_QTLEVGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_QTLEVGAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NRA_QTLEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_QTLEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_AGE
			ON NRG_AGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_AGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_AGE
			ON NRA_AGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_AGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_GEN
			ON NRG_GEN.PG_ExpEndYrID = @NatRateYear
			AND NRG_GEN.PG_SexID = CL.PG_SexID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_GEN
			ON NRA_GEN.PG_ExpEndYrID = @NatRateYear
			AND NRA_GEN.PG_SexID = CL.PG_SexID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_AgeLSCID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_GENAGE
			ON NRG_GENAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_GENAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRG_GENAGE.PG_SexID = CL.PG_SexID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_AgeLSCID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_GENAGE
			ON NRA_GENAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_GENAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NRA_GENAGE.PG_SexID = CL.PG_SexID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_NVQLevelCPRID = NULL,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_LEV
			ON NRG_LEV.PG_ExpEndYrID = @NatRateYear
			AND NRG_LEV.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_NVQLevelCPRID = NULL,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_LEV
			ON NRA_LEV.PG_ExpEndYrID = @NatRateYear
			AND NRA_LEV.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_NVQLevelCPRID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_LEVAGE
			ON NRG_LEVAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_LEVAGE.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
            AND NRG_LEVAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_NVQLevelCPRID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_LEVAGE
			ON NRA_LEVAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_LEVAGE.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
            AND NRA_LEVAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_NVQLevelGroupID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_LEVG
			ON NRG_LEVG.PG_ExpEndYrID = @NatRateYear
			AND NRG_LEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_NVQLevelGroupID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_LEVG
			ON NRA_LEVG.PG_ExpEndYrID = @NatRateYear
			AND NRA_LEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_NVQLevelGroupID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_LEVGAGE
			ON NRG_LEVGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_LEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
            AND NRG_LEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_NVQLevelGroupID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_LEVGAGE
			ON NRA_LEVGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_LEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
            AND NRA_LEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_EthnicityID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_ETH
			ON NRG_ETH.PG_ExpEndYrID = @NatRateYear
			AND NRG_ETH.PG_EthnicityID = CL.PG_EthnicityID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_EthnicityID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_ETH
			ON NRA_ETH.PG_ExpEndYrID = @NatRateYear
			AND NRA_ETH.PG_EthnicityID = CL.PG_EthnicityID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_EthnicityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_ETHAGE
			ON NRG_ETHAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_ETHAGE.PG_EthnicityID = CL.PG_EthnicityID
            AND NRG_ETHAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_EthnicityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_ETHAGE
			ON NRA_ETHAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_ETHAGE.PG_EthnicityID = CL.PG_EthnicityID
            AND NRA_ETHAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

	SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_EthnicGroupID = NULL,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_ETHG
			ON NRG_ETHG.PG_ExpEndYrID = @NatRateYear
			AND NRG_ETHG.PG_EthnicGroupID = CL.PG_EthnicGroupID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_EthnicGroupID = NULL,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_ETHG
			ON NRA_ETHG.PG_ExpEndYrID = @NatRateYear
			AND NRA_ETHG.PG_EthnicGroupID = CL.PG_EthnicGroupID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_EthnicGroupID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_ETHGAGE
			ON NRG_ETHGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_ETHGAGE.PG_EthnicGroupID = CL.PG_EthnicGroupID
            AND NRG_ETHGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				PG_EthnicGroupID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_ETHGAGE
			ON NRA_ETHGAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_ETHGAGE.PG_EthnicGroupID = CL.PG_EthnicGroupID
            AND NRA_ETHGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA1ID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_SSA1
			ON NRG_SSA1.PG_ExpEndYrID = @NatRateYear
			AND NRG_SSA1.PG_SSA1ID = CL.PG_SSA1ID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA1ID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_SSA1
			ON NRA_SSA1.PG_ExpEndYrID = @NatRateYear
			AND NRA_SSA1.PG_SSA1ID = CL.PG_SSA1ID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA1ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_SSA1AGE
			ON NRG_SSA1AGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_SSA1AGE.PG_SSA1ID = CL.PG_SSA1ID
			AND NRG_SSA1AGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA1ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_SSA1AGE
			ON NRA_SSA1AGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_SSA1AGE.PG_SSA1ID = CL.PG_SSA1ID
			AND NRA_SSA1AGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA2ID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_SSA2
			ON NRG_SSA2.PG_ExpEndYrID = @NatRateYear
			AND NRG_SSA2.PG_SSA2ID = CL.PG_SSA2ID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA2ID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_SSA2
			ON NRA_SSA2.PG_ExpEndYrID = @NatRateYear
			AND NRA_SSA2.PG_SSA2ID = CL.PG_SSA2ID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA2ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRG_SSA2AGE
			ON NRG_SSA2AGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_SSA2AGE.PG_SSA2ID = CL.PG_SSA2ID
			AND NRG_SSA2AGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_SSA2ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NRA_SSA2AGE
			ON NRA_SSA2AGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_SSA2AGE.PG_SSA2ID = CL.PG_SSA2ID
			AND NRA_SSA2AGE.PG_AgeLSCID = CL.PG_AgeLSCID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_DifficultyOrDisabilityID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NRG_DIF
			ON NRG_DIF.PG_ExpEndYrID = @NatRateYear
			AND NRG_DIF.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_DifficultyOrDisabilityID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NRA_DIF
			ON NRA_DIF.PG_ExpEndYrID = @NatRateYear
			AND NRA_DIF.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
	'

    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_DifficultyOrDisabilityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2 --GFE
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NRG_DIFAGE
			ON NRG_DIFAGE.PG_ExpEndYrID = @NatRateYear
			AND NRG_DIFAGE.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
            AND NRG_DIFAGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_ExpEndYrID,
				NR.PG_DifficultyOrDisabilityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Timely / 100,
				RetPer = NULL,
				AchPer = NR.BM_AchCount_Timely / 100,
				PassPer = NULL
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Timely NR
			WHERE
				NR.PG_ExpEndYrID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0 --ALL
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NRA_DIFAGE
			ON NRA_DIFAGE.PG_ExpEndYrID = @NatRateYear
			AND NRA_DIFAGE.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
            AND NRA_DIFAGE.PG_AgeLSCID = CL.PG_AgeLSCID

		WHERE 
			CL.PG_ExpEndYrID = @AcademicYear
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