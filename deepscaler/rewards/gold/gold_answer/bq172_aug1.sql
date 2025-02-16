-- Task: Identify the drug with the highest total number of prescriptions in New York State during 2014.
SELECT drug_name
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
WHERE nppes_provider_state = 'NY'
GROUP BY drug_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;