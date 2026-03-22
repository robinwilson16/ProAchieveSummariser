CREATE OR ALTER PROCEDURE SPR_PRA_ProAchieveSummaryData_CLOverall
	@ProviderRef NVARCHAR(50),
	@AcademicYear NVARCHAR(5),
	@CollegeType INT,
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
	
	--DECLARE @ProviderID INT = 10004579 --Provider Ref of the college
	--DECLARE @ProviderRef NVARCHAR(50) = 'NewCollegeSwindon' --Reference to save into table in case title too long for charts etc.
	--DECLARE @AcademicYear NVARCHAR(5) = ''

	--SET @AcademicYear = (SELECT CFG.Value FROM Config CFG WHERE CFG.ConfigID = 'PRA_AcademicYearID')
	--SET @AcademicYear = '22/23' --Override
	--DECLARE @CollegeType INT = 2 --Type of national averages - 2=GFE, 0=All Institutions
	--DECLARE @Mode CHAR(1) = 'R' --I=Insert new yearly ProAchieve data leaving data for other years, R=Replace table
	--DECLARE @ProGeneralDatabaseLocation NVARCHAR(200) = 'Ventora.ProGeneral.dbo.' --Database/Linked Server location
	--DECLARE @ProAchieveDatabaseLocation NVARCHAR(200) = 'Ventora.ProAchieve.dbo.' --Database/Linked Server location
	--DECLARE @OutputTableLocation NVARCHAR(200) = 'ProAchieveDataSummariser.dbo.' --Location where the resulting ProAchieve Summary Data table will be created
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
		WHERE
			NR.PG_CollegeTypeID = @CollegeType

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
			LearnerRef = CL.PG_StudentID,
			LearnerName = CL.StudentName,
			Gender = CL.PG_SexID,
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
			DiffDissCode = CL.PG_DifficultyOrDisabilityID,
			DiffDissName = DIF.ShortDescription,
			DifficultyCode = CL.PG_DisabilityID,
			DifficultyName = DIS.Description,
			DifficultyShortName = DIS.ShortDescription,
			IsHighNeeds = COALESCE ( FAM.PG_LearnFAMTypeHNSID, 0 ),
			EHCPCode = FAM.PG_LearnFAMTypeEHCID,
			EHCPName = EHC.PG_LearnFAMTypeEHCName,
			EHCPShortName = EHC.PG_LearnFAMTypeEHCShortName,
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
			SSA1Code = CL.PG_SSA1ID,
			SSA1Name = SSA1.SSA_Tier1_Desc,
			SSA2Code = CL.PG_SSA2ID,
			SSA2Name = SSA2.SSA_Tier2_Desc,
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
			CompletionCode = CL.PG_CompletionID,
			CompletionName = CMP.ShortDescription,
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
			AimRef = AIM.GN_AimID,
			AimName = AIM.GN_AimName,
			QualTypeCode = CL.PG_QualSizeID,
			QualTypeName = QS.PG_QualSizeName,
			LARSAimTypeCode = CL.PG_QType1ID,
			LARSAimTypeName = QT.PG_LearningAimTypeName,
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
			NVQLevelGrpCode = LVL.PG_NVQLevelGroupID,
			NVQLevelGrpName = LVLG.Description,
			LevelOfStudyCode = NULL,
			LevelOfStudyName = NULL,
			QOECode = NULL,
			QOEName = NULL,
			AwardBody = AIM.PG_AwardBodyID,
			Grade = CL.PG_GradeID,

			FundModelCode = 
				CASE
					WHEN CL.FundType = ''16-19 (excluding Apprenticeships)'' THEN ''1619''
					WHEN CL.FundType = ''Adult skills'' THEN ''ADULT''
					WHEN CL.FundType = ''24+ Loan'' THEN ''LOAN''
					ELSE ''X''
				END,
			FundModelName = 
				CASE
					WHEN CL.FundType = ''16-19 (excluding Apprenticeships)'' THEN ''16-19 Funded''
					WHEN CL.FundType = ''Adult skills'' THEN ''Adult Funded''
					WHEN CL.FundType = ''24+ Loan'' THEN ''Loan Funded''
					ELSE ''-- Unknown --''
				END,
			FundStream = CL.PG_FundingStreamID,
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
			AttendPer = 
				ROUND (
					CASE
						WHEN CL.Att_Exp = 0 THEN 0
						ELSE CAST ( CL.Att_Act AS FLOAT ) / CAST ( CL.Att_Exp AS FLOAT )
					END
				, 4 ),
			LessonsLate = CL.Att_Lat,
			PuncPer = 
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
			NatRate_Yr_Leave = NR_YR.Leave,
			NatRate_Yr_Comp = NR_YR.Comp,
			NatRate_Yr_RetPer = NR_YR.RetPer,
			NatRate_Yr_Ach = NR_YR.Ach,
			NatRate_Yr_AchPer = NR_YR.AchPer,
			NatRate_Yr_Pass = NR_YR.Pass,
			NatRate_Yr_PassPer = NR_YR.PassPer,
			NatRate_YrALL_Leave = NR_YRA.Leave,
			NatRate_YrALL_Comp = NR_YRA.Comp,
			NatRate_YrALL_RetPer = NR_YRA.RetPer,
			NatRate_YrALL_Ach = NR_YRA.Ach,
			NatRate_YrALL_AchPer = NR_YRA.AchPer,
			NatRate_YrALL_Pass = NR_YRA.Pass,
			NatRate_YrALL_PassPer = NR_YRA.PassPer,
			NatRate_YrGFE_Leave = NR_YRG.Leave,
			NatRate_YrGFE_Comp = NR_YRG.Comp,
			NatRate_YrGFE_RetPer = NR_YRG.RetPer,
			NatRate_YrGFE_Ach = NR_YRG.Ach,
			NatRate_YrGFE_AchPer = NR_YRG.AchPer,
			NatRate_YrGFE_Pass = NR_YRG.Pass,
			NatRate_YrGFE_PassPer = NR_YRG.PassPer,
			NatRate_Aim_Leave = NR_AIM.BM_Count_Overall,
			NatRate_Aim_Comp = ROUND ( ( CAST ( NR_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NR_AIM.BM_RetCount_Overall, 0 ),
			NatRate_Aim_RetPer = NR_AIM.BM_RetCount_Overall / 100,
			NatRate_Aim_Ach = ROUND ( ( CAST ( NR_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NR_AIM.BM_AchCount_Overall, 0 ),
			NatRate_Aim_AchPer = NR_AIM.BM_AchCount_Overall / 100,
			NatRate_Aim_Pass = ROUND ( ( CAST ( NR_AIM.BM_Count_Overall AS FLOAT ) / 100 ) * NR_AIM.BM_AchComplete_Overall, 0 ),
			NatRate_Aim_PassPer = NR_AIM.BM_AchComplete_Overall / 100,
			NatRate_Standard_Leave = NULL,
			NatRate_Standard_Comp = NULL,
			NatRate_Standard_RetPer = NULL,
			NatRate_Standard_Ach = NULL,
			NatRate_Standard_AchPer = NULL,
			NatRate_Standard_Pass = NULL,
			NatRate_Standard_PassPer = NULL,
			NatRate_FrameworkProg_Leave = NULL,
			NatRate_FrameworkProg_Comp = NULL,
			NatRate_FrameworkProg_RetPer = NULL,
			NatRate_FrameworkProg_Ach = NULL,
			NatRate_FrameworkProg_AchPer = NULL,
			NatRate_FrameworkProg_Pass = NULL,
			NatRate_FrameworkProg_PassPer = NULL,
			NatRate_Framework_Leave = NULL,
			NatRate_Framework_Comp = NULL,
			NatRate_Framework_RetPer = NULL,
			NatRate_Framework_Ach = NULL,
			NatRate_Framework_AchPer = NULL,
			NatRate_Framework_Pass = NULL,
			NatRate_Framework_PassPer = NULL,
			NatRate_FworkPTSSA_Leave = NULL,
			NatRate_FworkPTSSA_Comp = NULL,
			NatRate_FworkPTSSA_RetPer = NULL,
			NatRate_FworkPTSSA_Ach = NULL,
			NatRate_FworkPTSSA_AchPer = NULL,
			NatRate_FworkPTSSA_Pass = NULL,
			NatRate_FworkPTSSA_PassPer = NULL,
			NatRate_Age_Leave = NR_AGE.Leave,
			NatRate_Age_Comp = NR_AGE.Comp,
			NatRate_Age_RetPer = NR_AGE.RetPer,
			NatRate_Age_Ach = NR_AGE.Ach,
			NatRate_Age_AchPer = NR_AGE.AchPer,
			NatRate_Age_Pass = NR_AGE.Pass,
			NatRate_Age_PassPer = NR_AGE.PassPer,
			NatRate_Gender_Leave = NR_GEN.Leave,
			NatRate_Gender_Comp = NR_GEN.Comp,
			NatRate_Gender_RetPer = NR_GEN.RetPer,
			NatRate_Gender_Ach = NR_GEN.Ach,
			NatRate_Gender_AchPer = NR_GEN.AchPer,
			NatRate_Gender_Pass = NR_GEN.Pass,
			NatRate_Gender_PassPer = NR_GEN.PassPer,
			NatRate_GenderAge_Leave = NR_GENAGE.Leave,
			NatRate_GenderAge_Comp = NR_GENAGE.Comp,
			NatRate_GenderAge_RetPer = NR_GENAGE.RetPer,
			NatRate_GenderAge_Ach = NR_GENAGE.Ach,
			NatRate_GenderAge_AchPer = NR_GENAGE.AchPer,
			NatRate_GenderAge_Pass = NR_GENAGE.Pass,
			NatRate_GenderAge_PassPer = NR_GENAGE.PassPer,
			NatRate_Level_Leave = NR_LEV.Leave,
			NatRate_Level_Comp = NR_LEV.Comp,
			NatRate_Level_RetPer = NR_LEV.RetPer,
			NatRate_Level_Ach = NR_LEV.Ach,
			NatRate_Level_AchPer = NR_LEV.AchPer,
			NatRate_Level_Pass = NR_LEV.Pass,
			NatRate_Level_PassPer = NR_LEV.PassPer,
            NatRate_LevelAge_Leave = NR_LEVAGE.Leave,
			NatRate_LevelAge_Comp = NR_LEVAGE.Comp,
			NatRate_LevelAge_RetPer = NR_LEVAGE.RetPer,
			NatRate_LevelAge_Ach = NR_LEVAGE.Ach,
			NatRate_LevelAge_AchPer = NR_LEVAGE.AchPer,
			NatRate_LevelAge_Pass = NR_LEVAGE.Pass,
			NatRate_LevelAge_PassPer = NR_LEVAGE.PassPer,
            NatRate_LevelGrp_Leave = NR_LEVG.Leave,
			NatRate_LevelGrp_Comp = NR_LEVG.Comp,
			NatRate_LevelGrp_RetPer = NR_LEVG.RetPer,
			NatRate_LevelGrp_Ach = NR_LEVG.Ach,
			NatRate_LevelGrp_AchPer = NR_LEVG.AchPer,
			NatRate_LevelGrp_Pass = NR_LEVG.Pass,
			NatRate_LevelGrp_PassPer = NR_LEVG.PassPer,
            NatRate_LevelGrpAge_Leave = NR_LEVGAGE.Leave,
			NatRate_LevelGrpAge_Comp = NR_LEVGAGE.Comp,
			NatRate_LevelGrpAge_RetPer = NR_LEVGAGE.RetPer,
			NatRate_LevelGrpAge_Ach = NR_LEVGAGE.Ach,
			NatRate_LevelGrpAge_AchPer = NR_LEVGAGE.AchPer,
			NatRate_LevelGrpAge_Pass = NR_LEVGAGE.Pass,
			NatRate_LevelGrpAge_PassPer = NR_LEVGAGE.PassPer,
			NatRate_QualType_Leave = NR_QS.Leave,
			NatRate_QualType_Comp = NR_QS.Comp,
			NatRate_QualType_RetPer = NR_QS.RetPer,
			NatRate_QualType_Ach = NR_QS.Ach,
			NatRate_QualType_AchPer = NR_QS.AchPer,
			NatRate_QualType_Pass = NR_QS.Pass,
			NatRate_QualType_PassPer = NR_QS.PassPer,
			NatRate_QualTypeAge_Leave = NR_QSAGE.Leave,
			NatRate_QualTypeAge_Comp = NR_QSAGE.Comp,
			NatRate_QualTypeAge_RetPer = NR_QSAGE.RetPer,
			NatRate_QualTypeAge_Ach = NR_QSAGE.Ach,
			NatRate_QualTypeAge_AchPer = NR_QSAGE.AchPer,
			NatRate_QualTypeAge_Pass = NR_QSAGE.Pass,
			NatRate_QualTypeAge_PassPer = NR_QSAGE.PassPer,
			NatRate_Ethnicity_Leave = NR_ETH.Leave,
			NatRate_Ethnicity_Comp = NR_ETH.Comp,
			NatRate_Ethnicity_RetPer = NR_ETH.RetPer,
			NatRate_Ethnicity_Ach = NR_ETH.Ach,
			NatRate_Ethnicity_AchPer = NR_ETH.AchPer,
			NatRate_Ethnicity_Pass = NR_ETH.Pass,
			NatRate_Ethnicity_PassPer = NR_ETH.PassPer,
            NatRate_EthnicityAge_Leave = NR_ETHAGE.Leave,
			NatRate_EthnicityAge_Comp = NR_ETHAGE.Comp,
			NatRate_EthnicityAge_RetPer = NR_ETHAGE.RetPer,
			NatRate_EthnicityAge_Ach = NR_ETHAGE.Ach,
			NatRate_EthnicityAge_AchPer = NR_ETHAGE.AchPer,
			NatRate_EthnicityAge_Pass = NR_ETHAGE.Pass,
			NatRate_EthnicityAge_PassPer = NR_ETHAGE.PassPer,
			NatRate_EthnicGroup_Leave = NR_ETHG.Leave,
			NatRate_EthnicGroup_Comp = NR_ETHG.Comp,
			NatRate_EthnicGroup_RetPer = NR_ETHG.RetPer,
			NatRate_EthnicGroup_Ach = NR_ETHG.Ach,
			NatRate_EthnicGroup_AchPer = NR_ETHG.AchPer,
			NatRate_EthnicGroup_Pass = NR_ETHG.Pass,
			NatRate_EthnicGroup_PassPer = NR_ETHG.PassPer,
            NatRate_EthnicGroupAge_Leave = NR_ETHGAGE.Leave,
			NatRate_EthnicGroupAge_Comp = NR_ETHGAGE.Comp,
			NatRate_EthnicGroupAge_RetPer = NR_ETHGAGE.RetPer,
			NatRate_EthnicGroupAge_Ach = NR_ETHGAGE.Ach,
			NatRate_EthnicGroupAge_AchPer = NR_ETHGAGE.AchPer,
			NatRate_EthnicGroupAge_Pass = NR_ETHGAGE.Pass,
			NatRate_EthnicGroupAge_PassPer = NR_ETHGAGE.PassPer,
			NatRate_SSA1_Leave = NR_SSA1.Leave,
			NatRate_SSA1_Comp = NR_SSA1.Comp,
			NatRate_SSA1_RetPer = NR_SSA1.RetPer,
			NatRate_SSA1_Ach = NR_SSA1.Ach,
			NatRate_SSA1_AchPer = NR_SSA1.AchPer,
			NatRate_SSA1_Pass = NR_SSA1.Pass,
			NatRate_SSA1_PassPer = NR_SSA1.PassPer,
			NatRate_SSA1Age_Leave = NR_SSA1AGE.Leave,
			NatRate_SSA1Age_Comp = NR_SSA1AGE.Comp,
			NatRate_SSA1Age_RetPer = NR_SSA1AGE.RetPer,
			NatRate_SSA1Age_Ach = NR_SSA1AGE.Ach,
			NatRate_SSA1Age_AchPer = NR_SSA1AGE.AchPer,
			NatRate_SSA1Age_Pass = NR_SSA1AGE.Pass,
			NatRate_SSA1Age_PassPer = NR_SSA1AGE.PassPer,
			NatRate_SSA2_Leave = NR_SSA2.Leave,
			NatRate_SSA2_Comp = NR_SSA2.Comp,
			NatRate_SSA2_RetPer = NR_SSA2.RetPer,
			NatRate_SSA2_Ach = NR_SSA2.Ach,
			NatRate_SSA2_AchPer = NR_SSA2.AchPer,
			NatRate_SSA2_Pass = NR_SSA2.Pass,
			NatRate_SSA2_PassPer = NR_SSA2.PassPer,
			NatRate_SSA2Age_Leave = NR_SSA2AGE.Leave,
			NatRate_SSA2Age_Comp = NR_SSA2AGE.Comp,
			NatRate_SSA2Age_RetPer = NR_SSA2AGE.RetPer,
			NatRate_SSA2Age_Ach = NR_SSA2AGE.Ach,
			NatRate_SSA2Age_AchPer = NR_SSA2AGE.AchPer,
			NatRate_SSA2Age_Pass = NR_SSA2AGE.Pass,
			NatRate_SSA2Age_PassPer = NR_SSA2AGE.PassPer,
			NatRate_DifDis_Leave = NR_DIF.Leave,
			NatRate_DifDis_Comp = NR_DIF.Comp,
			NatRate_DifDis_RetPer = NR_DIF.RetPer,
			NatRate_DifDis_Ach = NR_DIF.Ach,
			NatRate_DifDis_AchPer = NR_DIF.AchPer,
			NatRate_DifDis_Pass = NR_DIF.Pass,
			NatRate_DifDis_PassPer = NR_DIF.PassPer,
            NatRate_DifDisAge_Leave = NR_DIFAGE.Leave,
			NatRate_DifDisAge_Comp = NR_DIFAGE.Comp,
			NatRate_DifDisAge_RetPer = NR_DIFAGE.RetPer,
			NatRate_DifDisAge_Ach = NR_DIFAGE.Ach,
			NatRate_DifDisAge_AchPer = NR_DIFAGE.AchPer,
			NatRate_DifDisAge_Pass = NR_DIFAGE.Pass,
			NatRate_DifDisAge_PassPer = NR_DIFAGE.PassPer
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
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_YR
			ON NR_YR.PG_HybridEndYearID = @NatRateYear
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = 0
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_YRA
			ON NR_YRA.PG_HybridEndYearID = @NatRateYear
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = 2
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_YRG
			ON NR_YRG.PG_HybridEndYearID = @NatRateYear
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_Qual_Overall NR_AIM
			ON NR_AIM.PG_HybridEndYearID = @NatRateYear
			AND NR_AIM.PG_CollegeTypeID = @CollegeType
			AND NR_AIM.PG_AimID = CL.PG_AimID
			AND NR_AIM.PG_MapID IS NULL
			AND NR_AIM.PG_AgeLSCID IS NULL
    '
    
    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_QualSizeID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_QS
			ON NR_QS.PG_HybridEndYearID = @NatRateYear
			AND NR_QS.PG_QualSizeID = CL.PG_QualSizeID
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_QualSizeID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NOT NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_QSAGE
			ON NR_QSAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_QSAGE.PG_QualSizeID = CL.PG_QualSizeID
			AND NR_QSAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'
    
    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_AGE
			ON NR_AGE.PG_HybridEndYearID = @NatRateYear
			AND NR_AGE.PG_AgeLSCID = CL.PG_AgeLSCID
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_GEN
			ON NR_GEN.PG_HybridEndYearID = @NatRateYear
			AND NR_GEN.PG_SexID = CL.PG_SexID
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_AgeLSCID,
				NR.PG_SexID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NOT NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_GENAGE
			ON NR_GENAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_GENAGE.PG_AgeLSCID = CL.PG_AgeLSCID
			AND NR_GENAGE.PG_SexID = CL.PG_SexID
    '
    
    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				PG_NVQLevelCPRID = NULL,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_LEV
			ON NR_LEV.PG_HybridEndYearID = @NatRateYear
			AND NR_LEV.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				PG_NVQLevelCPRID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_LEVAGE
			ON NR_LEVAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_LEVAGE.PG_NVQLevelCPRID = CL.PG_NVQLevelCPRID
            AND NR_LEVAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'
    
    SET @SQLString += 
        N'
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_NVQLevelGroupID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_LEVG
			ON NR_LEVG.PG_HybridEndYearID = @NatRateYear
			AND NR_LEVG.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_NVQLevelGroupID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NOT NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_LEVGAGE
			ON NR_LEVGAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_LEVGAGE.PG_NVQLevelGroupID = CL.PG_NVQLevelGroupID
            AND NR_LEVGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_EthnicityID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_ETH
			ON NR_ETH.PG_HybridEndYearID = @NatRateYear
			AND NR_ETH.PG_EthnicityID = CL.PG_EthnicityID
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_EthnicityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NOT NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_ETHAGE
			ON NR_ETHAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_ETHAGE.PG_EthnicityID = CL.PG_EthnicityID
            AND NR_ETHAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

	SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				PG_EthnicGroupID = NULL,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_ETHG
			ON NR_ETHG.PG_HybridEndYearID = @NatRateYear
			AND NR_ETHG.PG_EthnicGroupID = CL.PG_EthnicGroupID
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				PG_EthnicGroupID = NULL,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_ETHGAGE
			ON NR_ETHGAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_ETHGAGE.PG_EthnicGroupID = CL.PG_EthnicGroupID
            AND NR_ETHGAGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_SSA1ID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_SSA1
			ON NR_SSA1.PG_HybridEndYearID = @NatRateYear
			AND NR_SSA1.PG_SSA1ID = CL.PG_SSA1ID
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_SSA1ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NOT NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_SSA1AGE
			ON NR_SSA1AGE.PG_HybridEndYearID = @NatRateYear
			AND NR_SSA1AGE.PG_SSA1ID = CL.PG_SSA1ID
			AND NR_SSA1AGE.PG_AgeLSCID = CL.PG_AgeLSCID
	'

    SET @SQLString += 
		N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_SSA2ID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_SSA2
			ON NR_SSA2.PG_HybridEndYearID = @NatRateYear
			AND NR_SSA2.PG_SSA2ID = CL.PG_SSA2ID
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_SSA2ID,
				NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NOT NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NULL
		) NR_SSA2AGE
			ON NR_SSA2AGE.PG_HybridEndYearID = @NatRateYear
			AND NR_SSA2AGE.PG_SSA2ID = CL.PG_SSA2ID
			AND NR_SSA2AGE.PG_AgeLSCID = CL.PG_AgeLSCID
    '

    SET @SQLString += 
        N'
		LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_DifficultyOrDisabilityID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NR_DIF
			ON NR_DIF.PG_HybridEndYearID = @NatRateYear
			AND NR_DIF.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
        LEFT JOIN (
			SELECT
				NR.PG_HybridEndYearID,
				NR.PG_DifficultyOrDisabilityID,
                NR.PG_AgeLSCID,
				Leave = NR.BM_Count_Overall,
				Comp = NULL,
				Ach = NULL,
				Pass = NULL,
				RetPer = NR.BM_RetCount_Overall / 100,
				AchPer = NR.BM_AchCount_Overall / 100,
				PassPer = NR.BM_AchComplete_Overall / 100
			FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_CL_High_Overall NR
			WHERE
				NR.PG_HybridEndYearID = @NatRateYear
				AND NR.PG_CollegeTypeID = @CollegeType
				AND NR.PG_AgeLSCID IS NOT NULL
				AND NR.PG_NVQLevelGroupID IS NULL
				AND NR.PG_QualSizeID IS NULL
				AND NR.PG_SSA1ID IS NULL
				AND NR.PG_SSA2ID IS NULL
				AND NR.PG_SexID IS NULL
				AND NR.PG_EthnicityID IS NULL
				AND NR.PG_DifficultyOrDisabilityID IS NOT NULL
		) NR_DIFAGE
			ON NR_DIFAGE.PG_HybridEndYearID = @NatRateYear
			AND NR_DIFAGE.PG_DifficultyOrDisabilityID = CL.PG_DifficultyOrDisabilityID
            AND NR_DIFAGE.PG_AgeLSCID = CL.PG_AgeLSCID

		WHERE 
			CL.PG_HybridEndYearID = @AcademicYear
			--AND MYS.LastAcademicYearID = @AcademicYear
	'

	--SELECT @SQLString AS [processing-instruction(x)] FOR XML PATH('')

	SET @SQLParams = 
        N'@ProviderRef NVARCHAR(50),
		@AcademicYear NVARCHAR(5),
	    @CollegeType INT,
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
        @CollegeType = @CollegeType,
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