WITH top_families AS (
    SELECT 
        "family_id",
        COUNT(*) AS "pub_ct"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY "pub_ct" DESC NULLS LAST
    LIMIT 6
)

SELECT 
    p."family_id",
    a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      AS p
JOIN top_families                                      AS tf
      ON p."family_id" = tf."family_id"
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       AS a
      ON p."publication_number" = a."publication_number"
WHERE a."abstract" IS NOT NULL
  AND TRIM(a."abstract") <> ''
ORDER BY p."family_id";