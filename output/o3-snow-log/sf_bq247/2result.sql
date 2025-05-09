WITH top_families AS (          -- 1. six biggest families (ignore “-1”)
    SELECT
        "family_id",
        COUNT(*) AS pub_cnt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY pub_cnt DESC NULLS LAST
    LIMIT 6
), pubs AS (                     -- 2. all publications belonging to those families
    SELECT
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    JOIN top_families                               tf
      ON p."family_id" = tf."family_id"
)
SELECT DISTINCT                  -- 3. family-id + every non-empty abstract
       pubs."family_id",
       ae."abstract"
FROM pubs
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
  ON ae."publication_number" = pubs."publication_number"
WHERE ae."abstract" IS NOT NULL
  AND TRIM(ae."abstract") <> ''
ORDER BY pubs."family_id";