SELECT 
    CoC_Number, 
    CoC_Name,
    SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans ELSE 0 END) -
    SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans ELSE 0 END) AS Change_in_Homeless_Veterans
FROM 
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE 
    CoC_Number LIKE 'NY%' AND 
    Count_Year IN (2012, 2018)
GROUP BY 
    CoC_Number, 
    CoC_Name
ORDER BY 
    Change_in_Homeless_Veterans DESC;