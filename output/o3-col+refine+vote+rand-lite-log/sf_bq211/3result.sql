SELECT 
    COUNT(DISTINCT p."publication_number") AS "cn_granted_2010_2023_in_families_with_gt1_app"
FROM PATENTS.PATENTS.PUBLICATIONS p
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231
  AND p."family_id" IN (
        SELECT "family_id"
        FROM PATENTS.PATENTS.PUBLICATIONS
        GROUP BY "family_id"
        HAVING COUNT(DISTINCT "application_number") > 1
     );