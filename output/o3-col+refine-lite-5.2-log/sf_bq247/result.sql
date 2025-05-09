/* 1) Pick the six simple‑family IDs with the largest publication counts
   2) Join those families’ publications to ABS_AND_EMB
   3) Return every non‑empty abstract together with its family_id         */
WITH top_families AS (
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST, "family_id"
    LIMIT 6
)

SELECT
    p."family_id",
    a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"  p
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"   a
      ON p."publication_number" = a."publication_number"
JOIN top_families tf
      ON p."family_id" = tf."family_id"
WHERE a."abstract" IS NOT NULL
  AND a."abstract" <> ''
ORDER BY p."family_id";