/* 1) Pick the six most-populated families (ignoring dummy id ‘-1’)
   2) Join to ABS_AND_EMB via publication_number
   3) Return every non-blank abstract that belongs to those families            */
WITH top_families AS (
    SELECT
        p."family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" AS p
    WHERE p."family_id" <> '-1'
    GROUP BY p."family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
)
SELECT
    p."family_id",
    a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  AS p
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"   AS a
      ON p."publication_number" = a."publication_number"
JOIN top_families tf
      ON p."family_id" = tf."family_id"
WHERE a."abstract" IS NOT NULL
  AND a."abstract" <> ''
ORDER BY p."family_id";