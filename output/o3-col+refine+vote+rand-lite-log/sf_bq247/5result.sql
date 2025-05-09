WITH top_families AS (   -- 1. find the six largest families (ignoring the catch-all value ‘-1’)
    SELECT
        "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC
    LIMIT 6
),

family_abstracts AS (    -- 2. collect every non-empty abstract that belongs to those families
    SELECT
        p."family_id",
        a."abstract"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS     p
    JOIN top_families                                     tf ON p."family_id"       = tf."family_id"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB      a  ON p."publication_number" = a."publication_number"
    WHERE a."abstract" IS NOT NULL
      AND a."abstract" <> ''
)

-- 3. return each family-id alongside every associated abstract
SELECT
    "family_id",
    "abstract"
FROM family_abstracts
ORDER BY "family_id";