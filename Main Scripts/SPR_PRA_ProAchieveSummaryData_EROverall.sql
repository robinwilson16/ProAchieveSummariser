CREATE OR ALTER PROCEDURE SPR_PRA_ProAchieveSummaryData_EROverall
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
			@NatRateYear = MAX ( NR.WB_HybridEndYearID )
		FROM ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NR
	'
    

    SET @SQLString += 
        N'
		INSERT INTO ' + @OutputTableLocation + 'PRA_ProAchieveSummaryData WITH (TABLOCKX)
		SELECT
			EndYear = ER.WB_HybridEndYearID,
			AcademicYear = AY.PG_AcademicYearID,
			StartYear = ER.PG_StartYrID,
			ProvisionType = ''ER'',
			SummaryType = ''Overall'',
			SummaryMeasure =
                CASE
                    WHEN 
                        MYS.DefaultSummary = 1
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
			AcademicYears = MYS.ER_MYSName,
			NumYears = MYS.Years,
			LastAcademicYear = MYS.LastAcademicYearID,
			RulesApplied = MYS.RulesApplied,
			LastUpdated = MYS.LastUpdated,
	'
    
    SET @SQLString += 
        N'
			LearnRefNumber = ER.PG_StudentID,
			LearnerName = STU.Surname + '', '' + STU.Forenames,
			Sex = ER.PG_SexID,
			AgeGroup = 
				CASE
					WHEN AGE.PG_WBLFundAgeGroupName = ''24+'' THEN ''24 +''
					ELSE AGE.PG_WBLFundAgeGroupName
				END,
			PostCodeUpliftCode = NULL,
			PostCodeUpliftName = NULL,
			PostCodeIsDisadvantaged = NULL,
			PostCodeHome = ER.HomePostcode,
			PostCodeCurrent = ER.CurrentPostcode,
			PostCodeDelivery = ER.DeliveryPostcode,
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
					WHEN ER.PG_FundingStreamID = ''25'' THEN COALESCE ( PCU.EFA_UPLIFT, 1 )
					WHEN ER.PG_FundingStreamID = ''35'' AND ER.PG_FrameworkID = ''000'' THEN COALESCE ( PCU.SFA_UPLIFT, 1 )
					WHEN ER.PG_FundingStreamID = ''35'' AND ER.PG_FrameworkID <> ''000'' THEN COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 )
					WHEN ER.PG_FundingStreamID = ''35'' THEN COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 )
					WHEN ER.PG_FundingStreamID = ''36'' THEN COALESCE ( PCU.APP_FUNDING_UPLIFT, 1 )
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
			HasDifficultyOrDisabilityCode = ER.PG_DifficultyOrDisabilityID,
			HasDifficultyOrDisabilityName = DIF.ShortDescription,
			DifficultyCode = ER.PG_DisabilityID,
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
			SubjectSectorArea1Code = ER.PG_SSA1ID,
			SubjectSectorArea1Name = SSA1.SSA_Tier1_Desc,
			SubjectSectorArea2Code = ER.PG_SSA2ID,
			SubjectSectorArea2Name = SSA2.SSA_Tier2_Desc,
			ProgTypeCode = ER.PG_ProgTypeID,
			ProgTypeShortName = PT.PG_ProgTypeShortName,
			ProgTypeName = PT.PG_ProgTypeName,
			StandardCode = ER.PG_AppStandardID,
			StandardName = STD.PG_AppStandardName,
			FrameworkCode = ER.PG_FrameworkID,
			FrameworkName = FWK.PG_FrameworkName,
			PathwayCode = PWAY.OriginalAppPathwayID,
			PathwayName = PWAY.AppPathwayName,
			CourseCode = ER.PG_AggCourseID,
			CourseName = CRS.PG_AggCourseName,
			GroupCode = ER.EnrolmentUserDefined1,
			ProviderAimMonitoring1 = ENR.ProviderAimMonitoring1,
			ProviderAimMonitoring2 = ENR.ProviderAimMonitoring2,
			ProviderAimMonitoring3 = ENR.AddProviderAimMonitoring1,
			ProviderAimMonitoring4 = ENR.AddProviderAimMonitoring2,
			StartDate = ER.StartDate,
			ExpEndDate = ER.PlannedEndDate,
			ExpEndDatePlus90Days = NULL,
			ActEndDate = ER.ActualEndDate,
			AchDate = ER.AchievementDate,
			StartPeriodID = ER.StartPeriodID,
			ExpEndPeriodID = ER.PG_PlannedEndMonthID,
			ActEndPeriodID = ER.LeavePeriodID,
			CompletionStatusCode = ER.PG_CompletionID,
			CompletionStatusName = CMP.ShortDescription,
			OutcomeCode = ER.PG_OutcomeID,
			OutcomeName = OC.ShortDescription,
			SubcontractorCode = ER.PG_SubContractorID,
			SubcontractorName = NULL,
			MinimumStandardThreshold = 62,
			MinimumStandardType = MINS.Type,
			MinimumStandardGroupCode = ER.Minimum_Standards_GroupID,
			MinimumStandardsGroupName = MSTD.Minimum_Standards_GroupName,
			SequenceNo = ER.SequenceNo,
    '

    SET @SQLString += 
        N'
			LearnAimRef = AIM.GN_AimID,
			LearnAimTitle = AIM.GN_AimName,
			LearningAimTypeCode = NULL,
			LearningAimTypeName = NULL,
			QualificationTypeCode = ER.PG_QualSizeID,
			QualificationTypeName = QS.PG_QualSizeName,
			AimTypeCode = ER.PG_ILRAimTypeID,
			AimTypeName = NULL,
			DurationCode = ER.WB_DurationID,
			DurationName = DUR.WB_DurationName,
			DurationGroupCode = NULL,
			DurationGroupName = NULL,
			DurationTypeCode = NULL,
			DurationTypeName = NULL,
			DurationTypeGroupCode = NULL,
			DurationTypeGroupName = NULL,

			EngOrMathsCode = ''X'',
			EngOrMathsName = ''Neither'',
			NVQLevelCode = ER.PG_NVQLevelID,
			NVQLevelName = LVLC.PG_NVQLevelCPRName,
			NVQLevelGroupCode = LVL.PG_NVQLevelGroupID,
			NVQLevelGroupName = LVLG.Description,
			LevelOfStudyCode = NULL,
			LevelOfStudyName = NULL,
			QOECode = NULL,
			QOEName = NULL,
			AwardingBody = AIM.PG_AwardBodyID,
			Grade = NULL,

			FundingModelCode = ''APP'',
			FundingModelName = ''Apprenticeship'',
			FundingStream = ER.PG_FundingStreamID,
			IsEFAFunded = 0,
			IsAdvLearnLoanFunded = 0,
			IsStart = 
				WBCount 
				-
				CASE
					WHEN ER.WBCount = 0 THEN 0
					WHEN ER.WBXfr + ER.WBWithdrawnin6Wks > 0  THEN 1
					WHEN ER.WBPlannedBreak - ER.WBOverdue > 0 THEN 1
					ELSE 0
				END,
			IsLeaver = 
				CASE
					WHEN 
						ER.WBOverdue = 1
						AND 
							ER.WBLeave 
							- 
							CASE WHEN ER.WBLeave = 0 THEN 0
								WHEN ER.WBLSCExcludeOverall + ER.WBWithdrawnin6Wks > 0 THEN 1
								ELSE 0
							END = 0
						AND 
							ER.WBAchFrame 
							- 
							CASE 
								WHEN ER.WBAchFrame = 0 THEN 0
								WHEN ER.WBCont + ER.WBLSCExcludeOverall > 0 THEN 1
								ELSE 0
							END = 0
						AND ER.WBWithdrawnin6Wks = 0
							THEN 1
					ELSE
						ER.WBLeave 
						- 
						CASE WHEN ER.WBLeave = 0 THEN 0
							WHEN ER.WBLSCExcludeOverall + ER.WBWithdrawnin6Wks > 0 THEN 1
							ELSE 0
						END
				END,
			IsLeaverBestCase = 
				CASE
					WHEN 
						ER.WBOverdue = 1
						AND 
							ER.WBLeave 
							- 
							CASE WHEN ER.WBLeave = 0 THEN 0
								WHEN ER.WBLSCExcludeOverall + ER.WBWithdrawnin6Wks > 0 THEN 1
								ELSE 0
							END = 0
						AND 
							ER.WBAchFrame 
							- 
							CASE 
								WHEN ER.WBAchFrame = 0 THEN 0
								WHEN ER.WBCont + ER.WBLSCExcludeOverall > 0 THEN 1
								ELSE 0
							END = 0
						AND ER.WBWithdrawnin6Wks = 0
							THEN 1
					ELSE
						ER.WBLeave 
						- 
						CASE WHEN ER.WBLeave = 0 THEN 0
							WHEN ER.WBLSCExcludeOverall + ER.WBWithdrawnin6Wks > 0 THEN 1
							ELSE 0
						END
				END
				+
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBCont
				END,
			LessonsExpected = ER.Att_Exp,
			LessonsAttended = ER.Att_Act,
			AttendancePer = 
				ROUND (
					CASE
						WHEN ER.Att_Exp = 0 THEN 0
						ELSE CAST ( ER.Att_Act AS FLOAT ) / CAST ( ER.Att_Exp AS FLOAT )
					END
				, 4 ),
			LessonsLate = ER.Att_Lat,
			PunctualityPer = 
				ROUND (
					CASE
						WHEN ER.Att_Act = 0 THEN 0
						ELSE 100 - CAST ( ER.Att_Lat AS FLOAT ) / CAST ( ER.Att_Act AS FLOAT )
					END
				, 4 ),
			IsXfr = ER.WBXfr,
			IsCont = 
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBCont
				END,
			IsWdr = ER.WBLeave,
			IsWdrInQualifyingPeriod = ER.WBWithdrawnin6Wks,
			IsWdrAfterQualifyingPeriod = 
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5,11,12) AND CASE WHEN WBWithdrawnFlag - WBWithdrawnin6Wks > 0 THEN 1 ELSE 0 END = 0 THEN 1
					ELSE CASE WHEN WBWithdrawnFlag - WBWithdrawnin6Wks > 0 THEN 1 ELSE 0 END
				END,
			IsPlannedBreak = ER.WBPlannedBreak,
			IsOutOfFunding30 = 
				CASE
					WHEN ER.WBContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, ER.PlannedEndDate, CAST ( GetDate() AS DATE ) ) <= 30 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsOutOfFunding60 = 
				CASE
					WHEN ER.WBContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, ER.PlannedEndDate, CAST ( GetDate() AS DATE ) ) BETWEEN 31 AND 60 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsOutOfFunding90 = 
				CASE
					WHEN ER.WBContinBeyondEnd = 1 THEN
						CASE
							WHEN DATEDIFF ( DAY, ER.PlannedEndDate, CAST ( GetDate() AS DATE ) ) BETWEEN 61 AND 90 THEN 1
							ELSE 0
						END
					ELSE 0
				END,
			IsComp = 
				CASE
					WHEN WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBRet - ER.WBCont
				END,
			IsRetInYr = 
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBRet
				END,
			IsRet = 
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBRet
				END,
			IsAch = 
				WBAchFrame 
				- 
				CASE 
					WHEN ER.WBAchFrame = 0 THEN 0
					WHEN ER.WBCont + ER.WBLSCExcludeOverall > 0 THEN 1
					ELSE 0
				END,
			IsAchBestCase = 
				WBAchFrame 
				- 
				CASE 
					WHEN ER.WBAchFrame = 0 THEN 0
					WHEN ER.WBCont + ER.WBLSCExcludeOverall > 0 THEN 1
					ELSE 0
				END
				+
				CASE
					WHEN ER.WBOverdue = 1 AND ER.WB_FrameworkStatusID IN (0,5) THEN 0
					ELSE ER.WBCont
				END
				+
				CASE
					WHEN ER.WB_FrameworkStatusID = 3 THEN ER.WBLeave
					ELSE 0
				END,
			IsPassHigh = 0,
			IsPassAToC = 0,
			FrameworkStatusCode = ER.WB_FrameworkStatusID,
			FrameworkStatusName = FWKS.WB_FrameworkStatusName,
			IsCompAwaitAch = 
				CASE
					WHEN ER.WB_FrameworkStatusID = 3 THEN ER.WBLeave
					ELSE 0
				END,
	'

    SET @SQLString += 
        N'
			NART_GFE_Overall_Leave = NRG_YR.BMLeave,
			NART_GFE_Overall_RetPer = NULL,
			NART_GFE_Overall_AchPer = CAST ( NRG_YR.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Overall_PassPer = NULL,
			NART_ALL_Overall_Leave = NRA_YR.BMLeave,
			NART_ALL_Overall_RetPer = NULL,
			NART_ALL_Overall_AchPer = CAST ( NRA_YR.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Overall_PassPer = NULL,

			NART_GFE_Aim_Leave = NULL,
			NART_GFE_Aim_Comp = NULL,
			NART_GFE_Aim_RetPer = NULL,
			NART_GFE_Aim_Ach = NULL,
			NART_GFE_Aim_AchPer = NULL,
			NART_GFE_Aim_Pass = NULL,
			NART_GFE_Aim_PassPer = NULL,
			NART_ALL_Aim_Leave = NULL,
			NART_ALL_Aim_Comp = NULL,
			NART_ALL_Aim_RetPer = NULL,
			NART_ALL_Aim_Ach = NULL,
			NART_ALL_Aim_AchPer = NULL,
			NART_ALL_Aim_Pass = NULL,
			NART_ALL_Aim_PassPer = NULL,

			NART_GFE_Standard_Leave = NRG_STD.BMLeave,
			NART_GFE_Standard_RetPer = NULL,
			NART_GFE_Standard_AchPer = CAST ( NRG_STD.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Standard_PassPer = NULL,
			NART_ALL_Standard_Leave = NRA_STD.BMLeave,
			NART_ALL_Standard_RetPer = NULL,
			NART_ALL_Standard_AchPer = CAST ( NRA_STD.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Standard_PassPer = NULL,

			NART_GFE_Framework_Leave = NRG_FWK.BMLeave,
			NART_GFE_Framework_RetPer = NULL,
			NART_GFE_Framework_AchPer = CAST ( NRG_FWK.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Framework_PassPer = NULL,
			NART_ALL_Framework_Leave = NRA_FWK.BMLeave,
			NART_ALL_Framework_RetPer = NULL,
			NART_ALL_Framework_AchPer = CAST ( NRA_FWK.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Framework_PassPer = NULL,

			NART_GFE_FrameworkProgType_Leave = NRG_FWKPRG.BMLeave,
			NART_GFE_FrameworkProgType_RetPer = NULL,
			NART_GFE_FrameworkProgType_AchPer = CAST ( NRG_FWKPRG.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_FrameworkProgType_PassPer = NULL,
			NART_ALL_FrameworkProgType_Leave = NRA_FWKPRG.BMLeave,
			NART_ALL_FrameworkProgType_RetPer = NULL,
			NART_ALL_FrameworkProgType_AchPer = CAST ( NRA_FWKPRG.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_FrameworkProgType_PassPer = NULL,

			NART_GFE_FrameworkProgTypeSSA_Leave = NRG_FWPGSSA.BMLeave,
			NART_GFE_FrameworkProgTypeSSA_RetPer = NULL,
			NART_GFE_FrameworkProgTypeSSA_AchPer = CAST ( NRG_FWPGSSA.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_FrameworkProgTypeSSA_PassPer = NULL,
			NART_ALL_FrameworkProgTypeSSA_Leave = NRA_FWPGSSA.BMLeave,
			NART_ALL_FrameworkProgTypeSSA_RetPer = NULL,
			NART_ALL_FrameworkProgTypeSSA_AchPer = CAST ( NRA_FWPGSSA.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_FrameworkProgTypeSSA_PassPer = NULL,
	'

	SET @SQLString += 
		N'
			NART_GFE_Age_Leave = NRG_AGE.BMLeave,
			NART_GFE_Age_RetPer = NULL,
			NART_GFE_Age_AchPer = CAST ( NRG_AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Age_PassPer = NULL,
			NART_ALL_Age_Leave = NRA_AGE.BMLeave,
			NART_ALL_Age_RetPer = NULL,
			NART_ALL_Age_AchPer = CAST ( NRA_AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Age_PassPer = NULL,

			NART_GFE_Sex_Leave = NRG_GEN.BMLeave,
			NART_GFE_Sex_RetPer = NULL,
			NART_GFE_Sex_AchPer = CAST ( NRG_GEN.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Sex_PassPer = NULL,
			NART_ALL_Sex_Leave = NRA_GEN.BMLeave,
			NART_ALL_Sex_RetPer = NULL,
			NART_ALL_Sex_AchPer = CAST ( NRA_GEN.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Sex_PassPer = NULL,

			NART_GFE_SexAge_Leave = NRG_GENAGE.BMLeave,
			NART_GFE_SexAge_RetPer = NULL,
			NART_GFE_SexAge_AchPer = CAST ( NRG_GENAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_SexAge_PassPer = NULL,
			NART_ALL_SexAge_Leave = NRA_GENAGE.BMLeave,
			NART_ALL_SexAge_RetPer = NULL,
			NART_ALL_SexAge_AchPer = CAST ( NRA_GENAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_SexAge_PassPer = NULL,

			NART_GFE_Level_Leave = NRG_LEV.BMLeave,
			NART_GFE_Level_RetPer = NULL,
			NART_GFE_Level_AchPer = CAST ( NRG_LEV.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Level_PassPer = NULL,
			NART_ALL_Level_Leave = NRA_LEV.BMLeave,
			NART_ALL_Level_RetPer = NULL,
			NART_ALL_Level_AchPer = CAST ( NRA_LEV.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Level_PassPer = NULL,

            NART_GFE_LevelAge_Leave = NRG_LEVAGE.BMLeave,
			NART_GFE_LevelAge_RetPer = NULL,
			NART_GFE_LevelAge_AchPer = CAST ( NRG_LEVAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_LevelAge_PassPer = NULL,
			NART_ALL_LevelAge_Leave = NRA_LEVAGE.BMLeave,
			NART_ALL_LevelAge_RetPer = NULL,
			NART_ALL_LevelAge_AchPer = CAST ( NRA_LEVAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_LevelAge_PassPer = NULL,

            NART_GFE_LevelGroup_Leave = NULL,
			NART_GFE_LevelGroup_RetPer = NULL,
			NART_GFE_LevelGroup_AchPer = NULL,
			NART_GFE_LevelGroup_PassPer = NULL,
			NART_ALL_LevelGroup_Leave = NULL,
			NART_ALL_LevelGroup_RetPer = NULL,
			NART_ALL_LevelGroup_AchPer = NULL,
			NART_ALL_LevelGroup_PassPer = NULL,

            NART_GFE_LevelGroupAge_Leave = NULL,
			NART_GFE_LevelGroupAge_RetPer = NULL,
			NART_GFE_LevelGroupAge_AchPer = NULL,
			NART_GFE_LevelGroupAge_PassPer = NULL,
			NART_ALL_LevelGroupAge_Leave = NULL,
			NART_ALL_LevelGroupAge_RetPer = NULL,
			NART_ALL_LevelGroupAge_AchPer = NULL,
			NART_ALL_LevelGroupAge_PassPer = NULL,
	'

	SET @SQLString += 
		N'
			NART_GFE_QualType_Leave = NULL,
			NART_GFE_QualType_RetPer = NULL,
			NART_GFE_QualType_AchPer = NULL,
			NART_GFE_QualType_PassPer = NULL,
			NART_ALL_QualType_Leave = NULL,
			NART_ALL_QualType_RetPer = NULL,
			NART_ALL_QualType_AchPer = NULL,
			NART_ALL_QualType_PassPer = NULL,

			NART_GFE_QualTypeAge_Leave = NULL,
			NART_GFE_QualTypeAge_RetPer = NULL,
			NART_GFE_QualTypeAge_AchPer = NULL,
			NART_GFE_QualTypeAge_PassPer = NULL,
			NART_ALL_QualTypeAge_Leave = NULL,
			NART_ALL_QualTypeAge_RetPer = NULL,
			NART_ALL_QualTypeAge_AchPer = NULL,
			NART_ALL_QualTypeAge_PassPer = NULL,

			NART_GFE_Ethnicity_Leave = NRG_ETH.BMLeave,
			NART_GFE_Ethnicity_RetPer = NULL,
			NART_GFE_Ethnicity_AchPer = CAST ( NRG_ETH.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_Ethnicity_PassPer = NULL,
			NART_ALL_Ethnicity_Leave = NRA_ETH.BMLeave,
			NART_ALL_Ethnicity_RetPer = NULL,
			NART_ALL_Ethnicity_AchPer = CAST ( NRA_ETH.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_Ethnicity_PassPer = NULL,

            NART_GFE_EthnicityAge_Leave = NRG_ETHAGE.BMLeave,
			NART_GFE_EthnicityAge_RetPer = NULL,
			NART_GFE_EthnicityAge_AchPer = CAST ( NRG_ETHAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_EthnicityAge_PassPer = NULL,
			NART_ALL_EthnicityAge_Leave = NRA_ETHAGE.BMLeave,
			NART_ALL_EthnicityAge_RetPer = NULL,
			NART_ALL_EthnicityAge_AchPer = CAST ( NRA_ETHAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_EthnicityAge_PassPer = NULL,

			NART_GFE_EthnicGroup_Leave = NULL,
			NART_GFE_EthnicGroup_RetPer = NULL,
			NART_GFE_EthnicGroup_AchPer = NULL,
			NART_GFE_EthnicGroup_PassPer = NULL,
			NART_ALL_EthnicGroup_Leave = NULL,
			NART_ALL_EthnicGroup_RetPer = NULL,
			NART_ALL_EthnicGroup_AchPer = NULL,
			NART_ALL_EthnicGroup_PassPer = NULL,

            NART_GFE_EthnicGroupAge_Leave = NULL,
			NART_GFE_EthnicGroupAge_RetPer = NULL,
			NART_GFE_EthnicGroupAge_AchPer = NULL,
			NART_GFE_EthnicGroupAge_PassPer = NULL,
			NART_ALL_EthnicGroupAge_Leave = NULL,
			NART_ALL_EthnicGroupAge_RetPer = NULL,
			NART_ALL_EthnicGroupAge_AchPer = NULL,
			NART_ALL_EthnicGroupAge_PassPer = NULL,
	'

	SET @SQLString += 
		N'
			NART_GFE_SSA1_Leave = NRG_SSA1.BMLeave,
			NART_GFE_SSA1_RetPer = NULL,
			NART_GFE_SSA1_AchPer = CAST ( NRG_SSA1.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_SSA1_PassPer = NULL,
			NART_ALL_SSA1_Leave = NRA_SSA1.BMLeave,
			NART_ALL_SSA1_RetPer = NULL,
			NART_ALL_SSA1_AchPer = CAST ( NRA_SSA1.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_SSA1_PassPer = NULL,

			NART_GFE_SSA1Age_Leave = NRG_SSA1AGE.BMLeave,
			NART_GFE_SSA1Age_RetPer = NULL,
			NART_GFE_SSA1Age_AchPer = CAST ( NRG_SSA1AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_SSA1Age_PassPer = NULL,
			NART_ALL_SSA1Age_Leave = NRA_SSA1AGE.BMLeave,
			NART_ALL_SSA1Age_RetPer = NULL,
			NART_ALL_SSA1Age_AchPer = CAST ( NRA_SSA1AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_SSA1Age_PassPer = NULL,

			NART_GFE_SSA2_Leave = NRG_SSA2.BMLeave,
			NART_GFE_SSA2_RetPer = NULL,
			NART_GFE_SSA2_AchPer = CAST ( NRG_SSA2.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_SSA2_PassPer = NULL,
			NART_ALL_SSA2_Leave = NRA_SSA2.BMLeave,
			NART_ALL_SSA2_RetPer = NULL,
			NART_ALL_SSA2_AchPer = CAST ( NRA_SSA2.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_SSA2_PassPer = NULL,

			NART_GFE_SSA2Age_Leave = NRG_SSA2AGE.BMLeave,
			NART_GFE_SSA2Age_RetPer = NULL,
			NART_GFE_SSA2Age_AchPer = CAST ( NRG_SSA2AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_SSA2Age_PassPer = NULL,
			NART_ALL_SSA2Age_Leave = NRA_SSA2AGE.BMLeave,
			NART_ALL_SSA2Age_RetPer = NULL,
			NART_ALL_SSA2Age_AchPer = CAST ( NRA_SSA2AGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_SSA2Age_PassPer = NULL,

			NART_GFE_DifDis_Leave = NRG_DIF.BMLeave,
			NART_GFE_DifDis_RetPer = NULL,
			NART_GFE_DifDis_AchPer = CAST ( NRG_DIF.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_DifDis_PassPer = NULL,
			NART_ALL_DifDis_Leave = NRA_DIF.BMLeave,
			NART_ALL_DifDis_RetPer = NULL,
			NART_ALL_DifDis_AchPer = CAST ( NRA_DIF.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_DifDis_PassPer = NULL,

            NART_GFE_DifDisAge_Leave = NRG_DIFAGE.BMLeave,
			NART_GFE_DifDisAge_RetPer = NULL,
			NART_GFE_DifDisAge_AchPer = CAST ( NRG_DIFAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_GFE_DifDisAge_PassPer = NULL,
			NART_ALL_DifDisAge_Leave = NRG_DIFAGE.BMLeave,
			NART_ALL_DifDisAge_RetPer = NULL,
			NART_ALL_DifDisAge_AchPer = CAST ( NRG_DIFAGE.BMAchFrameOverallLeave AS FLOAT ) / 100.00,
			NART_ALL_DifDisAge_PassPer = NULL
	'

    SET @SQLString += 
        N'
		FROM ' + @ProAchieveDatabaseLocation + 'ER_StudentProgram ER
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_AcademicYear AY
			ON AY.AcademicYearNumber = ER.AcademicYearNumber
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'vER_MYS_RDS_Seln MYS
			ON MYS.ER_MYSID = ER.ER_MYSID
            --AND MYS.DefaultSummary = 1
            AND MYS.IsArchived = 0
            -- AND MYS.IsQSRSummary = 0
            --AND MYS.RulesApplied = 0
            --AND MYS.IncludeAllAimTypes = 1
            AND MYS.LastAcademicYearID = (
                SELECT 
                    MaxYear = MAX ( MYS2.LastAcademicYearID )
                FROM ' + @ProAchieveDatabaseLocation + 'vER_MYS_RDS_Seln MYS2
                WHERE
                    MYS2.DefaultSummary = MYS.DefaultSummary
                    AND MYS2.IsArchived = MYS.IsArchived
                    AND MYS2.IsQSRSummary = MYS.IsQSRSummary
                    AND MYS2.RulesApplied = MYS.RulesApplied
                    AND MYS2.IncludeAllAimTypes = MYS.IncludeAllAimTypes
            )
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Student STU
			ON STU.StudentID = ER.PG_StudentID
			AND STU.AcademicYearID = AY.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PI_ER_Learner ENR 
			ON ENR.PG_ProviderID = ER.PG_ProviderID
			AND ENR.PG_AcademicYearID = AY.PG_AcademicYearID
			AND ENR.PG_StudentID = ER.PG_StudentID
			AND ENR.SequenceNo = ER.SequenceNo
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Aim AIM 
			ON AIM.GN_AimID = ER.PG_AimID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_Ethnicity ETH
			ON ETH.PG_EthnicityID = ER.PG_EthnicityID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicityGroupQAR ETHQ
			ON ETHQ.PG_EthnicityGroupQARID = ETH.PG_EthnicityGroupQARID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroup ETHG
			ON ETHG.PG_EthnicGroupID = ER.PG_EthnicGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_EthnicGroupSimple ETHGS
			ON ETHGS.PG_EthnicGroupSimpleID = ETHG.PG_EthnicGroupSimpleID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA1 SSA1 
			ON SSA1.SSA_Tier1_code = ER.PG_SSA1ID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'SSA2 SSA2 
			ON SSA2.SSA_Tier2_code = ER.PG_SSA2ID
	'

    SET @SQLString += 
        N'
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'WB_Duration DUR
			ON DUR.WB_DurationID = ER.WB_DurationID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'PG_ProgType PT
			ON PT.PG_ProgTypeID = ER.PG_ProgTypeID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'WB_ProgGroup PG
			ON PG.WB_ProgGroupID = PT.WB_ProgGroupID
		INNER JOIN ' + @ProAchieveDatabaseLocation + 'WB_FrameworkStatus FWKS
			ON FWKS.WB_FrameworkStatusID = ER.WB_FrameworkStatusID
		INNER JOIN ' + @ProGeneralDatabaseLocation + 'Completion CMP
			ON CMP.CompletionID = ER.PG_CompletionID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Outcome OC
			ON OC.OutcomeID = ER.PG_OutcomeID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_AppStandard STD
			ON STD.PG_AppStandardID = ER.PG_AppStandardID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_Framework FWK
			ON FWK.PG_FrameworkID = ER.PG_FrameworkID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'AppPathway PWAY
			ON PWAY.AppPathwayID = ER.PG_AppPathwayID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'Minimum_Standards_Group MSTD
			ON MSTD.Minimum_Standards_GroupID = ER.Minimum_Standards_GroupID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_WBLFundAgeGroup AGE 
			ON AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_QualSize QS
			ON QS.PG_QualSizeID = ER.PG_QualSizeID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PM_MS_ThresholdValue MINS
			ON MINS.PG_QualSizeID = ER.PG_QualSizeID
			AND MINS.ThresholdID = 1
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_Learner_FAM_Pivoted FAM
			ON FAM.PG_StudentID = ER.PG_StudentID
			AND FAM.PG_ProviderID = ER.PG_ProviderID
			AND FAM.PG_AcademicYearID = ER.WB_HybridEndYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnFAMTypeEHC EHC
			ON EHC.PG_LearnFAMTypeEHCID = FAM.PG_LearnFAMTypeEHCID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearningDelivery_FAM_Pivoted FAMLD
			ON FAMLD.PG_StudentID = ER.PG_StudentID
			AND FAMLD.PG_ProviderID = ER.PG_ProviderID
			AND FAMLD.PG_AcademicYearID = ER.WB_HybridEndYearID
			AND FAMLD.SequenceNo = ER.SequenceNo
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_LearnDelFAMTypeLSF LSF
			ON LSF.PG_LearnDelFAMTypeLSFID = FAMLD.PG_LearnDelFAMTypeLSFID
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevel LVL
			ON LVL.PG_NVQLevelID = ER.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NVQLevelCPR LVLC
			ON LVLC.PG_NVQLevelCPRID = ER.PG_NVQLevelID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'NVQLevelGroup LVLG
			ON LVLG.NVQLevelGroupID = LVL.PG_NVQLevelGroupID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeWard PCW
			ON PCW.Postcode = ER.HomePostcode
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'PostCodeUplift PCU
			ON PCU.POSTCODE = ER.HomePostcode
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure1IY L1 
			ON L1.GN_Structure1IYID = ER.PG_Structure1ID
			AND L1.PG_AcademicYearID = AY.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure2IY L2
			ON L2.GN_Structure2IYID = ER.PG_Structure2ID
			AND L2.PG_AcademicYearID = AY.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure3IY L3
			ON L3.GN_Structure3IYID = ER.PG_Structure3ID
			AND L3.PG_AcademicYearID = AY.PG_AcademicYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_Structure4IY L4
			ON L4.GN_Structure4IYID = ER.PG_Structure4ID
			AND L4.PG_AcademicYearID = AY.PG_AcademicYearID
		--LEFT JOIN ' + @ProAchieveDatabaseLocation + 'GN_CourseStructureIY CRS 
		--	ON CRS.PG_CourseID = ER.PG_AggCourseID
		--	AND CRS.PG_AcademicYearID = ER.PG_HybridEndYearID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_AggCourse CRS 
			ON CRS.PG_AggCourseID = ER.PG_AggCourseID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'DifficultyOrDisability DIF
			ON DIF.DifficultyOrDisabilityID = ER.PG_DifficultyOrDisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Disability DIS
			ON DIS.DisabilityID = ER.PG_DisabilityID
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Enrolment_Attendance ATT 
			ON ATT.StudentID = ER.PG_StudentID
			AND ATT.CollegeID = ER.PG_ProviderID
			AND ATT.AcademicYearID = ER.WB_HybridEndYearID
			AND ATT.SequenceNo = ER.SequenceNo
		LEFT JOIN ' + @ProGeneralDatabaseLocation + 'Student_UDF LAC
			ON LAC.StudentID = ER.PG_StudentID
			AND LAC.CollegeID = ER.PG_ProviderID
			AND LAC.AcademicYearID = ER.WB_HybridEndYearID
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_YR
			ON NRG_YR.WB_HybridEndYearID = @NatRateYear
			AND NRG_YR.PG_CollegeTypeID = 2 --GFE
			AND NRG_YR.PG_WBLFundAgeGroupID IS NULL
			AND NRG_YR.PG_SSA1ID IS NULL
			AND NRG_YR.PG_SSA2ID IS NULL
			AND NRG_YR.PG_ProgTypeID IS NULL
			AND NRG_YR.PG_EthnicityID IS NULL
			AND NRG_YR.PG_EthnicityGroupQARID IS NULL
			AND NRG_YR.PG_SexID IS NULL
			AND NRG_YR.PG_DifficultyorDisabilityID IS NULL
			AND NRG_YR.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_YR
			ON NRA_YR.WB_HybridEndYearID = @NatRateYear
			AND NRA_YR.PG_CollegeTypeID = 0 --ALL
			AND NRA_YR.PG_WBLFundAgeGroupID IS NULL
			AND NRA_YR.PG_SSA1ID IS NULL
			AND NRA_YR.PG_SSA2ID IS NULL
			AND NRA_YR.PG_ProgTypeID IS NULL
			AND NRA_YR.PG_EthnicityID IS NULL
			AND NRA_YR.PG_EthnicityGroupQARID IS NULL
			AND NRA_YR.PG_SexID IS NULL
			AND NRA_YR.PG_DifficultyorDisabilityID IS NULL
			AND NRA_YR.PG_LearningDifficultyID IS NULL
    '

	SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRG_STD
			ON NRG_STD.WB_HybridEndYearID = @NatRateYear
			AND NRG_STD.PG_CollegeTypeID = 2 --GFE
			AND NRG_STD.PG_WBLFundAgeGroupID IS NULL
			AND NRG_STD.PG_SSA1ID IS NULL
			AND NRG_STD.PG_SSA2ID IS NULL
			AND NRG_STD.PG_ProgTypeID IS NULL
			AND NRG_STD.PG_FrameworkID IS NULL
			AND NRG_STD.PG_AppStandardID = ER.PG_AppStandardID
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRA_STD
			ON NRA_STD.WB_HybridEndYearID = @NatRateYear
			AND NRA_STD.PG_CollegeTypeID = 0 --ALL
			AND NRA_STD.PG_WBLFundAgeGroupID IS NULL
			AND NRA_STD.PG_SSA1ID IS NULL
			AND NRA_STD.PG_SSA2ID IS NULL
			AND NRA_STD.PG_ProgTypeID IS NULL
			AND NRA_STD.PG_FrameworkID IS NULL
			AND NRA_STD.PG_AppStandardID = ER.PG_AppStandardID
	'

	SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRG_FWK
			ON NRG_FWK.WB_HybridEndYearID = @NatRateYear
			AND NRG_FWK.PG_CollegeTypeID = 2 --GFE
			AND NRG_FWK.PG_WBLFundAgeGroupID IS NULL
			AND NRG_FWK.PG_SSA1ID IS NULL
			AND NRG_FWK.PG_SSA2ID IS NULL
			AND NRG_FWK.PG_ProgTypeID IS NULL
			AND NRG_FWK.PG_FrameworkID = ER.PG_FrameworkID
			AND NRG_FWK.PG_AppStandardID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRA_FWK
			ON NRA_FWK.WB_HybridEndYearID = @NatRateYear
			AND NRA_FWK.PG_CollegeTypeID = 0 --ALL
			AND NRA_FWK.PG_WBLFundAgeGroupID IS NULL
			AND NRA_FWK.PG_SSA1ID IS NULL
			AND NRA_FWK.PG_SSA2ID IS NULL
			AND NRA_FWK.PG_ProgTypeID IS NULL
			AND NRA_FWK.PG_FrameworkID = ER.PG_FrameworkID
			AND NRA_FWK.PG_AppStandardID IS NULL
	'

	SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRG_FWKPRG
			ON NRG_FWKPRG.WB_HybridEndYearID = @NatRateYear
			AND NRG_FWKPRG.PG_CollegeTypeID = 2 --GFE
			AND NRG_FWKPRG.PG_WBLFundAgeGroupID IS NULL
			AND NRG_FWKPRG.PG_SSA1ID IS NULL
			AND NRG_FWKPRG.PG_SSA2ID IS NULL
			AND NRG_FWKPRG.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRG_FWKPRG.PG_FrameworkID = ER.PG_FrameworkID
			AND NRG_FWKPRG.PG_AppStandardID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRA_FWKPRG
			ON NRA_FWKPRG.WB_HybridEndYearID = @NatRateYear
			AND NRA_FWKPRG.PG_CollegeTypeID = 0 --ALL
			AND NRA_FWKPRG.PG_WBLFundAgeGroupID IS NULL
			AND NRA_FWKPRG.PG_SSA1ID IS NULL
			AND NRA_FWKPRG.PG_SSA2ID IS NULL
			AND NRA_FWKPRG.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRA_FWKPRG.PG_FrameworkID = ER.PG_FrameworkID
			AND NRA_FWKPRG.PG_AppStandardID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRG_FWPGSSA 
			ON NRG_FWPGSSA.WB_HybridEndYearID = @NatRateYear
			AND NRG_FWPGSSA.PG_CollegeTypeID = 2 --GFE
			AND NRG_FWPGSSA.PG_WBLFundAgeGroupID IS NULL
			AND NRG_FWPGSSA.PG_SSA1ID = ER.PG_SSA1ID
			AND NRG_FWPGSSA.PG_SSA2ID = ER.PG_SSA2ID
			AND NRG_FWPGSSA.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRG_FWPGSSA.PG_FrameworkID = ER.PG_FrameworkID
			AND NRG_FWPGSSA.PG_AppStandardID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Fwrk_Overall NRA_FWPGSSA 
			ON NRA_FWPGSSA.WB_HybridEndYearID = @NatRateYear
			AND NRA_FWPGSSA.PG_CollegeTypeID = 0 --ALL
			AND NRA_FWPGSSA.PG_WBLFundAgeGroupID IS NULL
			AND NRA_FWPGSSA.PG_SSA1ID = ER.PG_SSA1ID
			AND NRA_FWPGSSA.PG_SSA2ID = ER.PG_SSA2ID
			AND NRA_FWPGSSA.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRA_FWPGSSA.PG_FrameworkID = ER.PG_FrameworkID
			AND NRA_FWPGSSA.PG_AppStandardID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_AGE
			ON NRG_AGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_AGE.PG_SSA1ID IS NULL
			AND NRG_AGE.PG_SSA2ID IS NULL
			AND NRG_AGE.PG_ProgTypeID IS NULL
			AND NRG_AGE.PG_EthnicityID IS NULL
			AND NRG_AGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_AGE.PG_SexID IS NULL
			AND NRG_AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_AGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_AGE
			ON NRA_AGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_AGE.PG_SSA1ID IS NULL
			AND NRA_AGE.PG_SSA2ID IS NULL
			AND NRA_AGE.PG_ProgTypeID IS NULL
			AND NRA_AGE.PG_EthnicityID IS NULL
			AND NRA_AGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_AGE.PG_SexID IS NULL
			AND NRA_AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_AGE.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_GEN
			ON NRG_GEN.WB_HybridEndYearID = @NatRateYear
			AND NRG_GEN.PG_CollegeTypeID = 2 --GFE
			AND NRG_GEN.PG_WBLFundAgeGroupID IS NULL
			AND NRG_GEN.PG_SSA1ID IS NULL
			AND NRG_GEN.PG_SSA2ID IS NULL
			AND NRG_GEN.PG_ProgTypeID IS NULL
			AND NRG_GEN.PG_EthnicityID IS NULL
			AND NRG_GEN.PG_EthnicityGroupQARID IS NULL
			AND NRG_GEN.PG_SexID = ER.PG_SexID
			AND NRG_GEN.PG_DifficultyorDisabilityID IS NULL
			AND NRG_GEN.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_GEN
			ON NRA_GEN.WB_HybridEndYearID = @NatRateYear
			AND NRA_GEN.PG_CollegeTypeID = 0 --ALL
			AND NRA_GEN.PG_WBLFundAgeGroupID IS NULL
			AND NRA_GEN.PG_SSA1ID IS NULL
			AND NRA_GEN.PG_SSA2ID IS NULL
			AND NRA_GEN.PG_ProgTypeID IS NULL
			AND NRA_GEN.PG_EthnicityID IS NULL
			AND NRA_GEN.PG_EthnicityGroupQARID IS NULL
			AND NRA_GEN.PG_SexID = ER.PG_SexID
			AND NRA_GEN.PG_DifficultyorDisabilityID IS NULL
			AND NRA_GEN.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_GENAGE
			ON NRG_GENAGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_GENAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_GENAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_GENAGE.PG_SSA1ID IS NULL
			AND NRG_GENAGE.PG_SSA2ID IS NULL
			AND NRG_GENAGE.PG_ProgTypeID IS NULL
			AND NRG_GENAGE.PG_EthnicityID IS NULL
			AND NRG_GENAGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_GENAGE.PG_SexID = ER.PG_SexID
			AND NRG_GENAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_GENAGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_GENAGE
			ON NRA_GENAGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_GENAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_GENAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_GENAGE.PG_SSA1ID IS NULL
			AND NRA_GENAGE.PG_SSA2ID IS NULL
			AND NRA_GENAGE.PG_ProgTypeID IS NULL
			AND NRA_GENAGE.PG_EthnicityID IS NULL
			AND NRA_GENAGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_GENAGE.PG_SexID = ER.PG_SexID
			AND NRA_GENAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_GENAGE.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_SSA1
			ON NRG_SSA1.WB_HybridEndYearID = @NatRateYear
			AND NRG_SSA1.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA1.PG_WBLFundAgeGroupID IS NULL
			AND NRG_SSA1.PG_SSA1ID = ER.PG_SSA1ID
			AND NRG_SSA1.PG_SSA2ID IS NULL
			AND NRG_SSA1.PG_ProgTypeID IS NULL
			AND NRG_SSA1.PG_EthnicityID IS NULL
			AND NRG_SSA1.PG_EthnicityGroupQARID IS NULL
			AND NRG_SSA1.PG_SexID IS NULL
			AND NRG_SSA1.PG_DifficultyorDisabilityID IS NULL
			AND NRG_SSA1.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_SSA1
			ON NRA_SSA1.WB_HybridEndYearID = @NatRateYear
			AND NRA_SSA1.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA1.PG_WBLFundAgeGroupID IS NULL
			AND NRA_SSA1.PG_SSA1ID = ER.PG_SSA1ID
			AND NRA_SSA1.PG_SSA2ID IS NULL
			AND NRA_SSA1.PG_ProgTypeID IS NULL
			AND NRA_SSA1.PG_EthnicityID IS NULL
			AND NRA_SSA1.PG_EthnicityGroupQARID IS NULL
			AND NRA_SSA1.PG_SexID IS NULL
			AND NRA_SSA1.PG_DifficultyorDisabilityID IS NULL
			AND NRA_SSA1.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_SSA1AGE
			ON NRG_SSA1AGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_SSA1AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA1AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_SSA1AGE.PG_SSA1ID = ER.PG_SSA1ID
			AND NRG_SSA1AGE.PG_SSA2ID IS NULL
			AND NRG_SSA1AGE.PG_ProgTypeID IS NULL
			AND NRG_SSA1AGE.PG_EthnicityID IS NULL
			AND NRG_SSA1AGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_SSA1AGE.PG_SexID IS NULL
			AND NRG_SSA1AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_SSA1AGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_SSA1AGE
			ON NRA_SSA1AGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_SSA1AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA1AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_SSA1AGE.PG_SSA1ID = ER.PG_SSA1ID
			AND NRA_SSA1AGE.PG_SSA2ID IS NULL
			AND NRA_SSA1AGE.PG_ProgTypeID IS NULL
			AND NRA_SSA1AGE.PG_EthnicityID IS NULL
			AND NRA_SSA1AGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_SSA1AGE.PG_SexID IS NULL
			AND NRA_SSA1AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_SSA1AGE.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_SSA2
			ON NRG_SSA2.WB_HybridEndYearID = @NatRateYear
			AND NRG_SSA2.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA2.PG_WBLFundAgeGroupID IS NULL
			AND NRG_SSA2.PG_SSA1ID IS NULL
			AND NRG_SSA2.PG_SSA2ID = ER.PG_SSA2ID
			AND NRG_SSA2.PG_ProgTypeID IS NULL
			AND NRG_SSA2.PG_EthnicityID IS NULL
			AND NRG_SSA2.PG_EthnicityGroupQARID IS NULL
			AND NRG_SSA2.PG_SexID IS NULL
			AND NRG_SSA2.PG_DifficultyorDisabilityID IS NULL
			AND NRG_SSA2.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_SSA2
			ON NRA_SSA2.WB_HybridEndYearID = @NatRateYear
			AND NRA_SSA2.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA2.PG_WBLFundAgeGroupID IS NULL
			AND NRA_SSA2.PG_SSA1ID IS NULL
			AND NRA_SSA2.PG_SSA2ID = ER.PG_SSA2ID
			AND NRA_SSA2.PG_ProgTypeID IS NULL
			AND NRA_SSA2.PG_EthnicityID IS NULL
			AND NRA_SSA2.PG_EthnicityGroupQARID IS NULL
			AND NRA_SSA2.PG_SexID IS NULL
			AND NRA_SSA2.PG_DifficultyorDisabilityID IS NULL
			AND NRA_SSA2.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_SSA2AGE
			ON NRG_SSA2AGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_SSA2AGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_SSA2AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_SSA2AGE.PG_SSA1ID IS NULL
			AND NRG_SSA2AGE.PG_SSA2ID = ER.PG_SSA2ID
			AND NRG_SSA2AGE.PG_ProgTypeID IS NULL
			AND NRG_SSA2AGE.PG_EthnicityID IS NULL
			AND NRG_SSA2AGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_SSA2AGE.PG_SexID IS NULL
			AND NRG_SSA2AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_SSA2AGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_SSA2AGE
			ON NRA_SSA2AGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_SSA2AGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_SSA2AGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_SSA2AGE.PG_SSA1ID IS NULL
			AND NRA_SSA2AGE.PG_SSA2ID = ER.PG_SSA2ID
			AND NRA_SSA2AGE.PG_ProgTypeID IS NULL
			AND NRA_SSA2AGE.PG_EthnicityID IS NULL
			AND NRA_SSA2AGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_SSA2AGE.PG_SexID IS NULL
			AND NRA_SSA2AGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_SSA2AGE.PG_LearningDifficultyID IS NULL
    '

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_LEV
			ON NRG_LEV.WB_HybridEndYearID = @NatRateYear
			AND NRG_LEV.PG_CollegeTypeID = 2 --GFE
			AND NRG_LEV.PG_WBLFundAgeGroupID IS NULL
			AND NRG_LEV.PG_SSA1ID IS NULL
			AND NRG_LEV.PG_SSA2ID IS NULL
			AND NRG_LEV.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRG_LEV.PG_EthnicityID IS NULL
			AND NRG_LEV.PG_EthnicityGroupQARID IS NULL
			AND NRG_LEV.PG_SexID IS NULL
			AND NRG_LEV.PG_DifficultyorDisabilityID IS NULL
			AND NRG_LEV.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_LEV
			ON NRA_LEV.WB_HybridEndYearID = @NatRateYear
			AND NRA_LEV.PG_CollegeTypeID = 0 --ALL
			AND NRA_LEV.PG_WBLFundAgeGroupID IS NULL
			AND NRA_LEV.PG_SSA1ID IS NULL
			AND NRA_LEV.PG_SSA2ID IS NULL
			AND NRA_LEV.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRA_LEV.PG_EthnicityID IS NULL
			AND NRA_LEV.PG_EthnicityGroupQARID IS NULL
			AND NRA_LEV.PG_SexID IS NULL
			AND NRA_LEV.PG_DifficultyorDisabilityID IS NULL
			AND NRA_LEV.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_LEVAGE
			ON NRG_LEVAGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_LEVAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_LEVAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_LEVAGE.PG_SSA1ID IS NULL
			AND NRG_LEVAGE.PG_SSA2ID IS NULL
			AND NRG_LEVAGE.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRG_LEVAGE.PG_EthnicityID IS NULL
			AND NRG_LEVAGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_LEVAGE.PG_SexID IS NULL
			AND NRG_LEVAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_LEVAGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_LEVAGE
			ON NRA_LEVAGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_LEVAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_LEVAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_LEVAGE.PG_SSA1ID IS NULL
			AND NRA_LEVAGE.PG_SSA2ID IS NULL
			AND NRA_LEVAGE.PG_ProgTypeID = ER.PG_ProgTypeID
			AND NRA_LEVAGE.PG_EthnicityID IS NULL
			AND NRA_LEVAGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_LEVAGE.PG_SexID IS NULL
			AND NRA_LEVAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_LEVAGE.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
        LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_ETH
			ON NRG_ETH.WB_HybridEndYearID = @NatRateYear
			AND NRG_ETH.PG_CollegeTypeID = 2 --GFE
			AND NRG_ETH.PG_WBLFundAgeGroupID IS NULL
			AND NRG_ETH.PG_SSA1ID IS NULL
			AND NRG_ETH.PG_SSA2ID IS NULL
			AND NRG_ETH.PG_ProgTypeID IS NULL
			AND NRG_ETH.PG_EthnicityID = ER.PG_EthnicityID
			AND NRG_ETH.PG_EthnicityGroupQARID IS NULL
			AND NRG_ETH.PG_SexID IS NULL
			AND NRG_ETH.PG_DifficultyorDisabilityID IS NULL
			AND NRG_ETH.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_ETH
			ON NRA_ETH.WB_HybridEndYearID = @NatRateYear
			AND NRA_ETH.PG_CollegeTypeID = 0 --ALL
			AND NRA_ETH.PG_WBLFundAgeGroupID IS NULL
			AND NRA_ETH.PG_SSA1ID IS NULL
			AND NRA_ETH.PG_SSA2ID IS NULL
			AND NRA_ETH.PG_ProgTypeID IS NULL
			AND NRA_ETH.PG_EthnicityID = ER.PG_EthnicityID
			AND NRA_ETH.PG_EthnicityGroupQARID IS NULL
			AND NRA_ETH.PG_SexID IS NULL
			AND NRA_ETH.PG_DifficultyorDisabilityID IS NULL
			AND NRA_ETH.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
        LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_ETHAGE
			ON NRG_ETHAGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_ETHAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_ETHAGE.PG_ProgTypeID IS NULL
			AND NRG_ETHAGE.PG_SSA1ID IS NULL
			AND NRG_ETHAGE.PG_SSA2ID IS NULL
			AND NRG_ETHAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_ETHAGE.PG_SexID IS NULL
			AND NRG_ETHAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRG_ETHAGE.PG_LearningDifficultyID IS NULL
			AND NRG_ETHAGE.PG_EthnicityID = ER.PG_EthnicityID
			AND NRG_ETHAGE.PG_EthnicityGroupQARID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_ETHAGE
			ON NRA_ETHAGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_ETHAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_ETHAGE.PG_ProgTypeID IS NULL
			AND NRA_ETHAGE.PG_SSA1ID IS NULL
			AND NRA_ETHAGE.PG_SSA2ID IS NULL
			AND NRA_ETHAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_ETHAGE.PG_SexID IS NULL
			AND NRA_ETHAGE.PG_DifficultyorDisabilityID IS NULL
			AND NRA_ETHAGE.PG_LearningDifficultyID IS NULL
			AND NRA_ETHAGE.PG_EthnicityID = ER.PG_EthnicityID
			AND NRA_ETHAGE.PG_EthnicityGroupQARID IS NULL
    '

    SET @SQLString += 
        N'
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_DIF
			ON NRG_DIF.WB_HybridEndYearID = @NatRateYear
			AND NRG_DIF.PG_CollegeTypeID = 2 --GFE
			AND NRG_DIF.PG_WBLFundAgeGroupID IS NULL
			AND NRG_DIF.PG_SSA1ID IS NULL
			AND NRG_DIF.PG_SSA2ID IS NULL
			AND NRG_DIF.PG_ProgTypeID IS NULL
			AND NRG_DIF.PG_EthnicityID IS NULL
			AND NRG_DIF.PG_EthnicityGroupQARID IS NULL
			AND NRG_DIF.PG_SexID IS NULL
			AND NRG_DIF.PG_DifficultyorDisabilityID = ER.PG_DifficultyorDisabilityID
			AND NRG_DIF.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_DIF
			ON NRA_DIF.WB_HybridEndYearID = @NatRateYear
			AND NRA_DIF.PG_CollegeTypeID = 0 --ALL
			AND NRA_DIF.PG_WBLFundAgeGroupID IS NULL
			AND NRA_DIF.PG_SSA1ID IS NULL
			AND NRA_DIF.PG_SSA2ID IS NULL
			AND NRA_DIF.PG_ProgTypeID IS NULL
			AND NRA_DIF.PG_EthnicityID IS NULL
			AND NRA_DIF.PG_EthnicityGroupQARID IS NULL
			AND NRA_DIF.PG_SexID IS NULL
			AND NRA_DIF.PG_DifficultyorDisabilityID = ER.PG_DifficultyorDisabilityID
			AND NRA_DIF.PG_LearningDifficultyID IS NULL
	'

    SET @SQLString += 
        N'
        LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRG_DIFAGE
			ON NRG_DIFAGE.WB_HybridEndYearID = @NatRateYear
			AND NRG_DIFAGE.PG_CollegeTypeID = 2 --GFE
			AND NRG_DIFAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRG_DIFAGE.PG_SSA1ID IS NULL
			AND NRG_DIFAGE.PG_SSA2ID IS NULL
			AND NRG_DIFAGE.PG_ProgTypeID IS NULL
			AND NRG_DIFAGE.PG_EthnicityID IS NULL
			AND NRG_DIFAGE.PG_EthnicityGroupQARID IS NULL
			AND NRG_DIFAGE.PG_SexID IS NULL
			AND NRG_DIFAGE.PG_DifficultyorDisabilityID = ER.PG_DifficultyorDisabilityID
			AND NRG_DIFAGE.PG_LearningDifficultyID IS NULL
		LEFT JOIN ' + @ProAchieveDatabaseLocation + 'PG_NationalRates_APP_Demo_Overall NRA_DIFAGE
			ON NRA_DIFAGE.WB_HybridEndYearID = @NatRateYear
			AND NRA_DIFAGE.PG_CollegeTypeID = 0 --ALL
			AND NRA_DIFAGE.PG_WBLFundAgeGroupID = ER.PG_WBLFundAgeGroupID
			AND NRA_DIFAGE.PG_SSA1ID IS NULL
			AND NRA_DIFAGE.PG_SSA2ID IS NULL
			AND NRA_DIFAGE.PG_ProgTypeID IS NULL
			AND NRA_DIFAGE.PG_EthnicityID IS NULL
			AND NRA_DIFAGE.PG_EthnicityGroupQARID IS NULL
			AND NRA_DIFAGE.PG_SexID IS NULL
			AND NRA_DIFAGE.PG_DifficultyorDisabilityID = ER.PG_DifficultyorDisabilityID
			AND NRA_DIFAGE.PG_LearningDifficultyID IS NULL
		WHERE
			ER.WB_HybridEndYearID = @AcademicYear
			--ND MYS.LastAcademicYearID = @AcademicYear
			--Default filters applied in ProAchieve
			AND ER.IsNotFundedAllYears = 0
			AND PT.WB_ProgGroupID = 1
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