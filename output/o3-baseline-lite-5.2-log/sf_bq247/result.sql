WITH top_families AS (
    /* 1. Pick the six family IDs that have the largest number of publications    */
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST, "family_id"
    LIMIT 6
),

family_publications AS (
    /* 2. All publication numbers that belong to those six families              */
    SELECT
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
    JOIN top_families                                 f
      ON p."family_id" = f."family_id"
)

SELECT
    fp."family_id",
    ae."abstract"
FROM family_publications                               fp
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB        ae
  ON fp."publication_number" = ae."publication_number"
WHERE ae."abstract" IS NOT NULL                       /* keep only non‑empty abstracts */
  AND TRIM(ae."abstract") <> ''
ORDER BY
    fp."family_id",
    ae."publication_number";