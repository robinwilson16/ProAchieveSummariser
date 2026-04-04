CREATE NONCLUSTERED INDEX NI_PRA_ProAchieveSummaryData ON PRA_ProAchieveSummaryData (SummaryType, EndYear)
INCLUDE (ProviderID, ProviderName, AgeGroup, CampusID, FacCode, FacName, TeamCode, TeamName, SubcontractorCode, IsLeaver, IsComp, IsAch)

CREATE NONCLUSTERED INDEX NI2_PRA_ProAchieveSummaryData
ON [dbo].[PRA_ProAchieveSummaryData] ([SummaryType],[EndYear])
INCLUDE ([ProviderID],[AgeGroup],[NatRate_Age_Leave],[NatRate_Age_Comp],[NatRate_Age_Ach])