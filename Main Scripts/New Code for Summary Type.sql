SELECT
	SummaryType =
		'CL_Overall_'
        + CASE
            WHEN 
                MYS.IsArchived = 0
                AND MYS.IsQSRSummary = 0
                AND MYS.RulesApplied = 1
                AND MYS.IncludeAllAimTypes = 0
                THEN 'RulesApplied'
            WHEN 
                MYS.IsArchived = 0
                AND MYS.IsQSRSummary = 0
                AND MYS.RulesApplied = 0
                AND MYS.IncludeAllAimTypes = 1
                THEN 'AllAims'
            WHEN 
                MYS.IsArchived = 0
                AND MYS.IsQSRSummary = 1
                AND MYS.RulesApplied = 1
                AND MYS.IncludeAllAimTypes = 0
                THEN 'QAR'
            ELSE 'ERROR'
        END
		+ '_'
		+ CAST ( RIGHT ( YEAR ( MYS.Period_End_Overall ), 2 ) - 1 AS VARCHAR(2) ) + '/' + CAST ( RIGHT ( YEAR ( MYS.Period_End_Overall ), 2 ) AS VARCHAR(2) )
		+ CASE
			WHEN SS.Setting > 0 THEN '_Default'
			ELSE ''
		END
FROM CL_Midpoint CL
INNER JOIN CL_MYS MYS
	ON MYS.CL_MidpointID = CL.CL_MidpointID
	AND MYS.PG_ProviderID = CL.PG_ProviderID
	AND MYS.IsArchived = 0
LEFT JOIN SystemSetting SS
	ON SS.Setting = MYS.CL_MYSID
	AND SS.Code = 'DefaultCLSummary'