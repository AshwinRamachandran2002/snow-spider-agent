-- Task: From the 'fema_national_flood_insurance_program_claim_index' table, retrieve the total building damage amounts and total contents damage amounts reported under the National Flood Insurance Program by the NFIP community named 'City Of New York' for each year from 2010 through 2019 inclusive. Group and order the results by the year of loss (extracted from the 'date_of_loss' field) and the NFIP community name.

SELECT 
    YEAR(claims.date_of_loss)               AS year_of_loss,
    claims.nfip_community_name,
    SUM(claims.building_damage_amount) AS total_building_damage_amount,
    SUM(claims.contents_damage_amount) AS total_contents_damage_amount
FROM WEATHER__ENVIRONMENT.CYBERSYN.fema_national_flood_insurance_program_claim_index claims
WHERE 
    claims.nfip_community_name = 'City Of New York' 
    AND year_of_loss >=2010 AND year_of_loss <=2019
GROUP BY year_of_loss, claims.nfip_community_name
ORDER BY year_of_loss, claims.nfip_community_name;