WITH top_families AS (
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
),
pubs_in_top AS (
    SELECT
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS AS p
    JOIN top_families AS tf
      ON p."family_id" = tf."family_id"
)
SELECT
    pit."family_id",
    ae."abstract"
FROM pubs_in_top AS pit
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB AS ae
  ON pit."publication_number" = ae."publication_number"
WHERE ae."abstract" IS NOT NULL
  AND TRIM(ae."abstract") <> ''
ORDER BY pit."family_id";