WITH top_families AS (   -- 1. six largest families (ignore '-1')
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
),
family_pubs AS (         -- 2. publications that belong to those families
    SELECT
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    JOIN top_families                                   tf
      ON p."family_id" = tf."family_id"
),
family_abstracts AS (    -- 3. join with abstracts and keep non-empty ones
    SELECT
        fp."family_id",
        ae."abstract"
    FROM family_pubs                               fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
      ON fp."publication_number" = ae."publication_number"
    WHERE ae."abstract" IS NOT NULL
      AND LENGTH(TRIM(ae."abstract")) > 0
)
SELECT
    "family_id",
    "abstract"
FROM family_abstracts
ORDER BY "family_id";