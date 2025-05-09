WITH fam_counts AS (
    SELECT
        "family_id",
        COUNT(*) AS pub_cnt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
),
top6 AS (
    SELECT
        "family_id"
    FROM fam_counts
    ORDER BY pub_cnt DESC NULLS LAST
    LIMIT 6
)
SELECT DISTINCT
    p."family_id",
    a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
JOIN top6                                              t  ON p."family_id"         = t."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB        a  ON p."publication_number" = a."publication_number"
WHERE a."abstract" IS NOT NULL
  AND TRIM(a."abstract") <> ''
ORDER BY p."family_id";