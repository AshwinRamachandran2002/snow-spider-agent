/* 1) pick the six families with the largest publication counts (ignoring family_id = '-1')
   2) join to ABS_AND_EMB to pull every non-empty abstract that belongs to those families   */
WITH top_families AS (
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
)
SELECT DISTINCT
       p."family_id",
       a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
JOIN top_families                                     tf ON p."family_id"       = tf."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB     a  ON p."publication_number" = a."publication_number"
WHERE a."abstract" IS NOT NULL
  AND TRIM(a."abstract") <> ''
ORDER BY p."family_id", a."abstract";