WITH top_families AS (   -- 1. pick the six families that appear most often
    SELECT 
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL               -- ignore NULL
      AND "family_id" <> '-1'                   -- ignore sentinel value
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST           -- most-frequent first
    LIMIT 6
),
family_pubs AS (        -- 2. all publications that belong to those families
    SELECT 
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN top_families t
      ON p."family_id" = t."family_id"
)
-- 3. return every non-empty abstract for those publications
SELECT
    fp."family_id",
    a."publication_number",
    a."abstract"
FROM family_pubs fp
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
  ON fp."publication_number" = a."publication_number"
WHERE a."abstract" IS NOT NULL
  AND TRIM(a."abstract") <> ''
ORDER BY fp."family_id", a."publication_number";