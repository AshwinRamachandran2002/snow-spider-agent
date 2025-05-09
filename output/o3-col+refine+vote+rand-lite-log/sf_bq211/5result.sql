SELECT 
    COUNT(*) AS "cn_granted_2010_2023_with_multi_app_fam"
FROM PATENTS.PATENTS.PUBLICATIONS p
JOIN (
    -- families having more than one distinct application
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
) fam
  ON p."family_id" = fam."family_id"
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231;