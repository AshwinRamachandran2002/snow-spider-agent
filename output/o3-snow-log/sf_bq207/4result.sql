WITH "INDEPENDENT_CLAIMS" AS (         -- all independent patent-claim stats
    SELECT
        "pat_no",
        "claim_no",
        TRY_TO_NUMBER("word_ct") AS "word_count"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),

"PUB_MAP" AS (                         -- link patent numbers to publication numbers
    SELECT
        "pat_no",
        "publication_number"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH
    WHERE "pat_no" IS NOT NULL
      AND "publication_number" IS NOT NULL
),

"EARLIEST_PUBS" AS (                   -- keep only the first publication for each application
    SELECT
        "publication_number",
        "application_number",
        ROW_NUMBER() OVER (PARTITION BY "application_number"
                           ORDER BY "publication_date") AS "rn"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    WHERE "application_number" IS NOT NULL
)

SELECT
    ep."publication_number",
    ep."application_number",
    ic."claim_no",
    ic."word_count"
FROM "INDEPENDENT_CLAIMS" ic
JOIN "PUB_MAP"       pm ON ic."pat_no"           = pm."pat_no"
JOIN "EARLIEST_PUBS" ep ON pm."publication_number" = ep."publication_number"
WHERE ep."rn" = 1                               -- earliest publication only
ORDER BY ic."word_count" DESC NULLS LAST
LIMIT 100;