SELECT nppes_provider_state AS State,
       SUM(total_claim_count) AS Total_Claim_Count,
       ROUND(SUM(total_drug_cost), 4) AS Total_Drug_Cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
WHERE UPPER(drug_name) = 'AMLODIPINE BESYLATE'
GROUP BY State
ORDER BY Total_Claim_Count DESC
LIMIT 5;