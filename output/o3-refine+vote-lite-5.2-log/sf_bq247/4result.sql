WITH family_counts AS (   -- count how many publications each family has
    SELECT
        "family_id",
        COUNT(*) AS pub_cnt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE "family_id" IS NOT NULL
      AND "family_id" <> '-1'
    GROUP BY "family_id"
),

top_families AS (         -- keep the six biggest families
    SELECT
        "family_id"
    FROM family_counts
    ORDER BY pub_cnt DESC NULLS LAST, "family_id" ASC
    LIMIT 6
),

family_pubs AS (          -- all publications that belong to those families
    SELECT
        p."family_id",
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"   p
    JOIN top_families                                  tf
      ON p."family_id" = tf."family_id"
),

abstracts AS (            -- join to abs_and_emb to pick up non‑empty abstracts
    SELECT
        fp."family_id",
        a."abstract"
    FROM family_pubs                                    fp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"   a
      ON fp."publication_number" = a."publication_number"
    WHERE a."abstract" IS NOT NULL
      AND TRIM(a."abstract") <> ''
)

-- return every abstract for each of the six families
SELECT DISTINCT
    "family_id",
    "abstract"
FROM abstracts
ORDER BY "family_id" ASC, "abstract" ASC;