WITH top_families AS (
    /* 1. Pick the six families with the largest publication counts (excluding family_id = '-1') */
    SELECT "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
)

SELECT
    p."family_id",
    p."publication_number",
    a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   AS p
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB    AS a
      ON p."publication_number" = a."publication_number"
WHERE p."family_id" IN (SELECT "family_id" FROM top_families)
  AND a."abstract" IS NOT NULL
  AND TRIM(a."abstract") <> ''
ORDER BY p."family_id", p."publication_number";