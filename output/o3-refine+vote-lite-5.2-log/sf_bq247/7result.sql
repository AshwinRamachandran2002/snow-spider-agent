WITH top_families AS (   -- 1) pick the six biggest families (exclude '-1')
    SELECT
        "family_id"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS"
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
), fam_pubs AS (         -- 2) every publication belonging to those families
    SELECT
        p."family_id",
        p."publication_number"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p
    JOIN top_families tf
          ON p."family_id" = tf."family_id"
)
SELECT                    -- 3) return the family id and each non‑empty abstract
    fp."family_id",
    ae."abstract"
FROM fam_pubs fp
JOIN "PATENTS_GOOGLE"."PATENTS_GOOGLE"."ABS_AND_EMB" ae
      ON fp."publication_number" = ae."publication_number"
WHERE ae."abstract" IS NOT NULL
  AND TRIM(ae."abstract") <> ''
ORDER BY fp."family_id", ae."publication_number";