UPDATE PRA_ProAchieveSummaryData
SET
	CollegeCode = 'NCO',
	CollegeName = 'Northumberland College'
WHERE
	ProviderID = 10004760
	AND COALESCE ( CollegeCode, 'X' ) <> 'NCO'