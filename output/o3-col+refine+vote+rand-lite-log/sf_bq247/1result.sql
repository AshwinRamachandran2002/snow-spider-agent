WITH family_counts AS (   -- count publications per family_id (excluding placeholder)
    SELECT
        "family_id",
        COUNT(*) AS "pub_count"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
),
top_families AS (        -- keep the six most-prolific families
    SELECT
        "family_id"
    FROM family_counts
    ORDER BY "pub_count" DESC NULLS LAST
    LIMIT 6
)
SELECT DISTINCT          -- list every non-empty abstract for those families
       p."family_id",
       a."abstract"
FROM top_families tf
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
     ON p."family_id" = tf."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   a
     ON a."publication_number" = p."publication_number"
WHERE a."abstract" IS NOT NULL
  AND a."abstract" <> ''
ORDER BY p."family_id";