WITH top_families AS (
    SELECT
        "family_id",
        COUNT(*) AS "pub_cnt"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY "pub_cnt" DESC NULLS LAST, "family_id" ASC
    LIMIT 6
)
SELECT
    p."family_id",
    a."abstract"
FROM top_families tf
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON p."family_id" = tf."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
      ON a."publication_number" = p."publication_number"
WHERE a."abstract" IS NOT NULL
  AND a."abstract" <> ''
ORDER BY p."family_id", p."publication_number";