WITH fam_counts AS (   -- how many publications per family (ignoring the placeholder -1)
    SELECT
        "family_id",
        COUNT(*) AS pub_cnt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
),
top_families AS (      -- keep only the six largest families
    SELECT "family_id"
    FROM (
        SELECT
            "family_id",
            pub_cnt,
            RANK() OVER (ORDER BY pub_cnt DESC, "family_id") AS rnk
        FROM fam_counts
    )
    WHERE rnk <= 6
)
SELECT
    p."family_id",
    ae."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
JOIN top_families                                     tf ON p."family_id"      = tf."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       ae ON p."publication_number" = ae."publication_number"
WHERE ae."abstract" IS NOT NULL
  AND TRIM(ae."abstract") <> ''
ORDER BY
    p."family_id";