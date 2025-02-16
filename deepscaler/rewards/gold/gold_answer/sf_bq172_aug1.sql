-- Task: Which drug has the highest total number of prescriptions in New York State during 2014?
SELECT "drug_name", SUM("total_claim_count") AS "total_claims"
FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
WHERE "nppes_provider_state" = 'NY'
GROUP BY "drug_name"
ORDER BY "total_claims" DESC NULLS LAST
LIMIT 1;