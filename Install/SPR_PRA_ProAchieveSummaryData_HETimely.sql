CREATE OR ALTER PROCEDURE SPR_PRA_ProAchieveSummaryData_HETimely
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
		INSERT INTO ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData WITH (TABLOCKX)
		SELECT
			EndYear = HE.PG_ExpEndYrID,
			AcademicYear = HE.PG_AcademicYearID,
			StartYear = HE.PG_StartYearID,
			ProvisionType = ''HE'',
			SummaryType = ''Timely'',
			SummaryMeasure =
                CASE
                    WHEN 
                        MYS.DefaultSummary = 1
                        AND MYS.IsArchived = 0
                        AND MYS.RulesApplied = 0
                        AND MYS.IncludeAllAimTypes = 1
                        THEN ''AllAims''
                    ELSE ''ERROR''
                END,
			IsDefaultSummary = MYS.DefaultSummary,
			IsArchivedSummary = MYS.IsArchived,
			IsQSRSummary = 0,
			IsRulesAppliedSummary = MYS.RulesApplied,
			IsAllAimTypesSummary = MYS.IncludeAllAimTypes,
			ProviderID = MYS.PG_ProviderID,
			ProviderRef = @ProviderRef,
			ProviderName = MYS.PG_ProviderName,
			Summary = MYS.Description,
			SummaryStatus = MYS.Status,
			AcademicYears = MYS.HE_MYSName,
			NumYears = 0,
			LastAcademicYear = MYS.LastAcademicYearID,
			RulesApplied = MYS.RulesApplied,
			LastUpdated = MYS.LastUpdated,
	'
    
    SET @SQLString += 
        N'
			LearnerRef = HE.PG_StudentID,
			LearnerName = HE.StudentName,
			Gender = HE.PG_SexID,
			AgeGroup = AGE.HE_AgeGroupName,
			PostCodeUpliftCode = NULL,
			PostCodeUpliftName = NULL,
			PostCodeIsDisadvantaged = NULL,
			PostCodeHome = MP.HomePostcode,
			PostCodeCurrent = MP.CurrentPostcode,
			PostCodeDelivery = MP.DeliveryPostcode,
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
					WHEN HE.PG_FundingStreamID = ''25'' THEN COALESCE ( PCU.EFA_UPLIFT, 1 )
					WHEN HE.PG_FundingStreamID = ''35'' THEN COALESCE ( PCU.SFA_UPLIFT, 1 )
					WHEN HE.PG_FundingStreamID = ''36'' THEN COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 )
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
			DiffDissCode = HE.PG_DifficultyOrDisabilityID,
			DiffDissName = DIF.ShortDescription,
			DifficultyCode = HE.PG_DisabilityID,
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
			SSA1Code = HE.PG_SSA1ID,
			SSA1Name = SSA1.SSA_Tier1_Desc,
			SSA2Code = HE.PG_SSA2ID,
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
			CourseCode = HE.PG_AggCourseID,
			CourseName = CRS.PG_AggCourseName,
			GroupCode = HE.EnrolmentUserDefined1,
			ProviderAimMonitoring1 = NULL,
			ProviderAimMonitoring2 = NULL,
			ProviderAimMonitoring3 = NULL,
			ProviderAimMonitoring4 = NULL,
			StartDate = HE.StartDate,
			ExpEndDate = HE.PlannedEndDate,
			ExpEndDatePlus90Days = HE.PlannedEndDate_Plus90Days,
			ActEndDate = HE.ActualEndDate,
			AchDate = NULL,
			StartPeriodID = NULL,
			ExpEndPeriodID = NULL,
			ActEndPeriodID = NULL,
			CompletionCode = HE.PG_CompletionID,
			CompletionName = CMP.ShortDescription,
			OutcomeCode = HE.PG_OutcomeID,
			OutcomeName = OC.ShortDescription,
			SubcontractorCode = NULL,
			SubcontractorName = NULL,
			MinimumStandardThreshold = NULL,
			MinimumStandardType = NULL,
			MinimumStandardGroupCode = NULL,
			MinimumStandardsGroupName = NULL,
			SequenceNo = HE.SequenceNo,
    '

    SET @SQLString += 
        N'
			AimRef = AIM.GN_AimID,
			AimName = AIM.GN_AimName,
			QualTypeCode = HE.PG_QualSizeID,
			QualTypeName = QS.PG_QualSizeName,
			LARSAimTypeCode = NULL,
			LARSAimTypeName = NULL,
			AimTypeCode = NULL,
			AimTypeName = NULL,
			DurationCode = HE.PG_DurationID,
			DurationName = DUR.PG_DurationName,
			DurationGroupCode = HE.PG_DurationGroupID,
			DurationGroupName = DURG.PG_DurationGroupName,
			DurationTypeCode = HE.PG_DurationTypeID,
			DurationTypeName = DURT.PG_DurationTypeName,
			DurationTypeGroupCode = NULL,
			DurationTypeGroupName = NULL,

			EngOrMathsCode = ''X'',
			EngOrMathsName = ''Neither'',
			NVQLevelCode = HE.PG_NVQLevelID,
			NVQLevelName = LVLC.PG_NVQLevelCPRName,
			NVQLevelGrpCode = LVL.PG_NVQLevelGroupID,
			NVQLevelGrpName = LVLG.Description,
			LevelOfStudyCode = HE.HE_LevelofStudyID,
			LevelOfStudyName = LVL2.HE_LevelofStudyName,
			QOECode = HE.PG_HEQualsOnEntryID,
			QOEName = QOE.PG_HEQualsOnEntryName,
			AwardBody = AIM.PG_AwardBodyID,
			Grade = HE.PG_GradeID,

			FundModelCode = ''HE'',
			FundModelName = ''Higher Education'',
			FundStream = HE.PG_FundingStreamID,
			IsEFAFunded = 0,
			IsAdvLearnLoanFunded = 0,
			IsStart = HE.HEStart_Timely,
			IsLeaver = HE.P_Count_TimelyQSRExclude,
			IsLeaverBestCase = HE.P_Count_TimelyQSRExclude,
			LessonsExpected = HE.Att_Exp,
			LessonsAttended = HE.Att_Act,
			AttendPer = 
				ROUND (
					CASE
						WHEN HE.Att_Exp = 0 THEN 0
						ELSE CAST ( HE.Att_Act AS FLOAT ) / CAST ( HE.Att_Exp AS FLOAT )
					END
				, 4 ),
			LessonsLate = ATT.TotalLates,
			PuncPer = 
				ROUND (
					CASE
						WHEN HE.Att_Act = 0 THEN 0
						ELSE 100 - CAST ( ATT.TotalLates AS FLOAT ) / CAST ( HE.Att_Act AS FLOAT )
					END
				, 4 ),
			IsXfr = HE.PVXfr,
			IsCont = HE.PVCont,
			IsWdr = HE.PVWithdrawn + HE.PVWithdrawn1stNov,
			IsWdrInQualifyingPeriod = HE.PVWithdrawn,
			IsWdrAfterQualifyingPeriod = HE.PVWithdrawn1stNov,
			IsPlannedBreak = HE.P_Plan_Break_Timely,
			OutOfFunding30 = 0,
			OutOfFunding60 = 0,
			OutOfFunding90 = 0,
			IsComp = HE.P_Complete_TimelyQSRExclude,
			IsRetInYr = HE.PVCont + HE.P_Complete_TimelyQSRExclude,
			IsRet = HE.PVCont + HE.P_Complete_TimelyQSRExclude,
			IsAch = HE.P_Ach_TimelyQSRExclude,
			IsAchBestCase = HE.P_Ach_TimelyQSRExclude,
			IsPassHigh = HE.PVHigh,
			IsPassAToC = 0,
			FrameworkStatusCode = NULL,
			FrameworkStatusName = NULL,
			IsCompAwaitAch = NULL,
	'

    SET @SQLString += 
        N'
			NatRate_Yr_Leave = NULL,
			NatRate_Yr_Comp = NULL,
			NatRate_Yr_RetPer = NULL,
			NatRate_Yr_Ach = NULL,
			NatRate_Yr_AchPer = NULL,
			NatRate_Yr_Pass = NULL,
			NatRate_Yr_PassPer = NULL,
			NatRate_YrALL_Leave = NULL,
			NatRate_YrALL_Comp = NULL,
			NatRate_YrALL_RetPer = NULL,
			NatRate_YrALL_Ach = NULL,
			NatRate_YrALL_AchPer = NULL,
			NatRate_YrALL_Pass = NULL,
			NatRate_YrALL_PassPer = NULL,
			NatRate_YrGFE_Leave = NULL,
			NatRate_YrGFE_Comp = NULL,
			NatRate_YrGFE_RetPer = NULL,
			NatRate_YrGFE_Ach = NULL,
			NatRate_YrGFE_AchPer = NULL,
			NatRate_YrGFE_Pass = NULL,
			NatRate_YrGFE_PassPer = NULL,
			NatRate_Aim_Leave = NULL,
			NatRate_Aim_Comp = NULL,
			NatRate_Aim_RetPer = NULL,
			NatRate_Aim_Ach = NULL,
			NatRate_Aim_AchPer = NULL,
			NatRate_Aim_Pass = NULL,
			NatRate_Aim_PassPer = NULL,
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
			NatRate_Age_Leave = NULL,
			NatRate_Age_Comp = NULL,
			NatRate_Age_RetPer = NULL,
			NatRate_Age_Ach = NULL,
			NatRate_Age_AchPer = NULL,
			NatRate_Age_Pass = NULL,
			NatRate_Age_PassPer = NULL,
			NatRate_Gender_Leave = NULL,
			NatRate_Gender_Comp = NULL,
			NatRate_Gender_RetPer = NULL,
			NatRate_Gender_Ach = NULL,
			NatRate_Gender_AchPer = NULL,
			NatRate_Gender_Pass = NULL,
			NatRate_Gender_PassPer = NULL,
			NatRate_GenderAge_Leave = NULL,
			NatRate_GenderAge_Comp = NULL,
			NatRate_GenderAge_RetPer = NULL,
			NatRate_GenderAge_Ach = NULL,
			NatRate_GenderAge_AchPer = NULL,
			NatRate_GenderAge_Pass = NULL,
			NatRate_GenderAge_PassPer = NULL,
			NatRate_Level_Leave = NULL,
			NatRate_Level_Comp = NULL,
			NatRate_Level_RetPer = NULL,
			NatRate_Level_Ach = NULL,
			NatRate_Level_AchPer = NULL,
			NatRate_Level_Pass = NULL,
			NatRate_Level_PassPer = NULL,
            NatRate_LevelAge_Leave = NULL,
			NatRate_LevelAge_Comp = NULL,
			NatRate_LevelAge_RetPer = NULL,
			NatRate_LevelAge_Ach = NULL,
			NatRate_LevelAge_AchPer = NULL,
			NatRate_LevelAge_Pass = NULL,
			NatRate_LevelAge_PassPer = NULL,
            NatRate_LevelGrp_Leave = NULL,
			NatRate_LevelGrp_Comp = NULL,
			NatRate_LevelGrp_RetPer = NULL,
			NatRate_LevelGrp_Ach = NULL,
			NatRate_LevelGrp_AchPer = NULL,
			NatRate_LevelGrp_Pass = NULL,
			NatRate_LevelGrp_PassPer = NULL,
            NatRate_LevelGrpAge_Leave = NULL,
			NatRate_LevelGrpAge_Comp = NULL,
			NatRate_LevelGrpAge_RetPer = NULL,
			NatRate_LevelGrpAge_Ach = NULL,
			NatRate_LevelGrpAge_AchPer = NULL,
			NatRate_LevelGrpAge_Pass = NULL,
			NatRate_LevelGrpAge_PassPer = NULL,
			NatRate_QualType_Leave = NULL,
			NatRate_QualType_Comp = NULL,
			NatRate_QualType_RetPer = NULL,
			NatRate_QualType_Ach = NULL,
			NatRate_QualType_AchPer = NULL,
			NatRate_QualType_Pass = NULL,
			NatRate_QualType_PassPer = NULL,
			NatRate_QualTypeAge_Leave = NULL,
			NatRate_QualTypeAge_Comp = NULL,
			NatRate_QualTypeAge_RetPer = NULL,
			NatRate_QualTypeAge_Ach = NULL,
			NatRate_QualTypeAge_AchPer = NULL,
			NatRate_QualTypeAge_Pass = NULL,
			NatRate_QualTypeAge_PassPer = NULL,
			NatRate_Ethnicity_Leave = NULL,
			NatRate_Ethnicity_Comp = NULL,
			NatRate_Ethnicity_RetPer = NULL,
			NatRate_Ethnicity_Ach = NULL,
			NatRate_Ethnicity_AchPer = NULL,
			NatRate_Ethnicity_Pass = NULL,
			NatRate_Ethnicity_PassPer = NULL,
            NatRate_EthnicityAge_Leave = NULL,
			NatRate_EthnicityAge_Comp = NULL,
			NatRate_EthnicityAge_RetPer = NULL,
			NatRate_EthnicityAge_Ach = NULL,
			NatRate_EthnicityAge_AchPer = NULL,
			NatRate_EthnicityAge_Pass = NULL,
			NatRate_EthnicityAge_PassPer = NULL,
			NatRate_EthnicGroup_Leave = NULL,
			NatRate_EthnicGroup_Comp = NULL,
			NatRate_EthnicGroup_RetPer = NULL,
			NatRate_EthnicGroup_Ach = NULL,
			NatRate_EthnicGroup_AchPer = NULL,
			NatRate_EthnicGroup_Pass = NULL,
			NatRate_EthnicGroup_PassPer = NULL,
            NatRate_EthnicGroupAge_Leave = NULL,
			NatRate_EthnicGroupAge_Comp = NULL,
			NatRate_EthnicGroupAge_RetPer = NULL,
			NatRate_EthnicGroupAge_Ach = NULL,
			NatRate_EthnicGroupAge_AchPer = NULL,
			NatRate_EthnicGroupAge_Pass = NULL,
			NatRate_EthnicGroupAge_PassPer = NULL,
			NatRate_SSA1_Leave = NULL,
			NatRate_SSA1_Comp = NULL,
			NatRate_SSA1_RetPer = NULL,
			NatRate_SSA1_Ach = NULL,
			NatRate_SSA1_AchPer = NULL,
			NatRate_SSA1_Pass = NULL,
			NatRate_SSA1_PassPer = NULL,
			NatRate_SSA1Age_Leave = NULL,
			NatRate_SSA1Age_Comp = NULL,
			NatRate_SSA1Age_RetPer = NULL,
			NatRate_SSA1Age_Ach = NULL,
			NatRate_SSA1Age_AchPer = NULL,
			NatRate_SSA1Age_Pass = NULL,
			NatRate_SSA1Age_PassPer = NULL,
			NatRate_SSA2_Leave = NULL,
			NatRate_SSA2_Comp = NULL,
			NatRate_SSA2_RetPer = NULL,
			NatRate_SSA2_Ach = NULL,
			NatRate_SSA2_AchPer = NULL,
			NatRate_SSA2_Pass = NULL,
			NatRate_SSA2_PassPer = NULL,
			NatRate_SSA2Age_Leave = NULL,
			NatRate_SSA2Age_Comp = NULL,
			NatRate_SSA2Age_RetPer = NULL,
			NatRate_SSA2Age_Ach = NULL,
			NatRate_SSA2Age_AchPer = NULL,
			NatRate_SSA2Age_Pass = NULL,
			NatRate_SSA2Age_PassPer = NULL,
			NatRate_DifDis_Leave = NULL,
			NatRate_DifDis_Comp = NULL,
			NatRate_DifDis_RetPer = NULL,
			NatRate_DifDis_Ach = NULL,
			NatRate_DifDis_AchPer = NULL,
			NatRate_DifDis_Pass = NULL,
			NatRate_DifDis_PassPer = NULL,
            NatRate_DifDisAge_Leave = NULL,
			NatRate_DifDisAge_Comp = NULL,
			NatRate_DifDisAge_RetPer = NULL,
			NatRate_DifDisAge_Ach = NULL,
			NatRate_DifDisAge_AchPer = NULL,
			NatRate_DifDisAge_Pass = NULL,
			NatRate_DifDisAge_PassPer = NULL
	'

    SET @SQLString += 
        N'
		FROM ' + @ProAchieveDatabaseLocation + 'HE_MYS_Low HE
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'vHE_MYS_RDS_Seln MYS 
			ON MYS.HE_MYSID = HE.HE_MYSID
			AND MYS.PG_ProviderID = HE.PG_ProviderID
			--AND MYS.DefaultSummary = 1
            AND MYS.IsArchived = 0
            --AND MYS.RulesApplied = 0
            --AND MYS.IncludeAllAimTypes = 1
            AND MYS.LastAcademicYearID = (
                SELECT 
                    MaxYear = MAX ( MYS2.LastAcademicYearID )
                FROM ' + @ProAchieveDatabaseLocation + 'vHE_MYS_RDS_Seln MYS2
                WHERE
                    MYS2.DefaultSummary = MYS.DefaultSummary
                    AND MYS2.IsArchived = MYS.IsArchived
                    AND MYS2.RulesApplied = MYS.RulesApplied
                    AND MYS2.IncludeAllAimTypes = MYS.IncludeAllAimTypes
            )
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'HE_Midpoint MP
			ON MP.PG_ProviderID = HE.PG_ProviderID
			AND MP.PG_AcademicYearID = HE.PG_AcademicYearID
			AND MP.PG_StudentID = HE.PG_StudentID
			AND MP.SequenceNo = HE.SequenceNo
			AND MP.HE_MidpointID = MYS.HE_MidpointID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Student STU
			ON STU.StudentID = HE.PG_StudentID
			AND STU.AcademicYearID = HE.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Aim AIM 
			ON AIM.GN_AimID = HE.PG_AimID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_Ethnicity ETH
			ON ETH.PG_EthnicityID = HE.PG_EthnicityID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicityGroupQAR ETHQ
			ON ETHQ.PG_EthnicityGroupQARID = ETH.PG_EthnicityGroupQARID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroup ETHG
			ON ETHG.PG_EthnicGroupID = HE.PG_EthnicGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroupSimple ETHGS
			ON ETHGS.PG_EthnicGroupSimpleID = ETHG.PG_EthnicGroupSimpleID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA1 SSA1 
			ON SSA1.SSA_Tier1_code = HE.PG_SSA1ID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA2 SSA2 
			ON SSA2.SSA_Tier2_code = HE.PG_SSA2ID
	'

    SET @SQLString += 
        N'
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_Duration DUR
			ON DUR.PG_DurationID = HE.PG_DurationID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_DurationGroup DURG
			ON DURG.PG_DurationGroupID = HE.PG_DurationGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_DurationType DURT
			ON DURT.PG_DurationTypeID = HE.PG_DurationTypeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_QualSize QS
			ON QS.PG_QualSizeID = HE.PG_QualSizeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PM_MS_ThresholdValue MINS
			ON MINS.PG_QualSizeID = HE.PG_QualSizeID
			AND MINS.ThresholdID = 1
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Completion CMP
			ON CMP.CompletionID = HE.PG_CompletionID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Outcome OC
			ON OC.OutcomeID = HE.PG_OutcomeID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'HE_AgeGroup AGE 
			ON AGE.HE_AgeGroupID = HE.HE_AgeGroupID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_Learner_FAM_Pivoted FAM
			ON FAM.PG_StudentID = HE.PG_StudentID
			AND FAM.PG_ProviderID = HE.PG_ProviderID
			AND FAM.PG_AcademicYearID = HE.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnFAMTypeEHC EHC
			ON EHC.PG_LearnFAMTypeEHCID = FAM.PG_LearnFAMTypeEHCID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearningDelivery_FAM_Pivoted FAMLD
			ON FAMLD.PG_StudentID = HE.PG_StudentID
			AND FAMLD.PG_ProviderID = HE.PG_ProviderID
			AND FAMLD.PG_AcademicYearID = HE.PG_AcademicYearID
			AND FAMLD.SequenceNo = HE.SequenceNo
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnDelFAMTypeLSF LSF
			ON LSF.PG_LearnDelFAMTypeLSFID = FAMLD.PG_LearnDelFAMTypeLSFID
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevel LVL
			ON LVL.PG_NVQLevelID = HE.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevelCPR LVLC
			ON LVLC.PG_NVQLevelCPRID = HE.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'NVQLevelGroup LVLG
			ON LVLG.NVQLevelGroupID = LVL.PG_NVQLevelGroupID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'HE_LevelofStudy LVL2
			ON LVL2.HE_LevelofStudyID = HE.HE_LevelofStudyID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_HEQualsOnEntry QOE
			ON QOE.PG_HEQualsOnEntryID = HE.PG_HEQualsOnEntryID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeWard PCW
			ON PCW.Postcode = MP.HomePostcode
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeUplift PCU
			ON PCU.POSTCODE = MP.HomePostcode
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure1IY L1 
			ON L1.GN_Structure1IYID = HE.PG_Structure1ID
			AND L1.PG_AcademicYearID = HE.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure2IY L2
			ON L2.GN_Structure2IYID = HE.PG_Structure2ID
			AND L2.PG_AcademicYearID = HE.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure3IY L3
			ON L3.GN_Structure3IYID = HE.PG_Structure3ID
			AND L3.PG_AcademicYearID = HE.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure4IY L4
			ON L4.GN_Structure4IYID = HE.PG_Structure4ID
			AND L4.PG_AcademicYearID = HE.PG_AcademicYearID
		--LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_CourseStructureIY CRS 
		--	ON CRS.PG_CourseID = HE.PG_AggCourseID
		--	AND CRS.PG_AcademicYearID = HE.PG_ExpEndYrID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_AggCourse CRS 
			ON CRS.PG_AggCourseID = HE.PG_AggCourseID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'DifficultyOrDisability DIF
			ON DIF.DifficultyOrDisabilityID = HE.PG_DifficultyOrDisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Disability DIS
			ON DIS.DisabilityID = HE.PG_DisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Enrolment_Attendance ATT 
			ON ATT.StudentID = HE.PG_StudentID
			AND ATT.CollegeID = HE.PG_ProviderID
			AND ATT.AcademicYearID = HE.PG_AcademicYearID
			AND ATT.SequenceNo = HE.SequenceNo
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Student_UDF LAC
			ON LAC.StudentID = HE.PG_StudentID
			AND LAC.CollegeID = HE.PG_ProviderID
			AND LAC.AcademicYearID = HE.PG_AcademicYearID
	'

    SET @SQLString += 
        N'
		WHERE 
			HE.PG_ExpEndYrID = @AcademicYear
			--AND MYS.LastAcademicYearID = @AcademicYear'

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