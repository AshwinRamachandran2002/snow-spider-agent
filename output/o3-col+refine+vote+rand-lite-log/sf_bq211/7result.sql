WITH multi_app_families AS (             -- families that contain >1 distinct applications worldwide
    SELECT "family_id"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    GROUP  BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT COUNT(DISTINCT p."publication_number") AS "total_cn_patents_multi_application_fams"
FROM   PATENTS.PATENTS.PUBLICATIONS p
JOIN   multi_app_families m
       ON p."family_id" = m."family_id"
WHERE  p."country_code" = 'CN'
  AND  p."grant_date" BETWEEN 20100101 AND 20231231;