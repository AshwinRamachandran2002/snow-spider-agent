WITH IND_CLAIMS AS (   -- independent patent-claim statistics
    SELECT
        CAST(pc."word_ct" AS NUMBER)          AS "word_ct",
        pc."pat_no"                           AS "pat_no",
        pc."appl_id"                          AS "appl_id",
        pc."claim_no"                         AS "claim_no"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS" pc
    WHERE pc."ind_flg" = '1'
),

CLAIMS_W_PUB AS (      -- add publication numbers via match table
    SELECT
        ic.*,
        m."publication_number"                AS "publication_number"
    FROM IND_CLAIMS              ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH" m
          ON ic."pat_no" = m."pat_no"
),

PUB_INFO AS (          -- publication meta-data
    SELECT
        p."publication_number",
        p."application_number",
        p."publication_date"
    FROM PATENTS_USPTO.PATENTS."PUBLICATIONS" p
),

EARLIEST_PER_APP AS (  -- earliest publication per application
    SELECT
        "application_number",
        MIN("publication_date") AS "earliest_pub_date"
    FROM PUB_INFO
    GROUP BY "application_number"
),

CLAIMS_EARLIEST AS (   -- keep only claims whose publication is that earliest one
    SELECT
        cwp."publication_number",
        pi."application_number",
        cwp."claim_no",
        cwp."word_ct"
    FROM CLAIMS_W_PUB  cwp
    JOIN PUB_INFO      pi
          ON cwp."publication_number" = pi."publication_number"
    JOIN EARLIEST_PER_APP ep
          ON pi."application_number" = ep."application_number"
         AND pi."publication_date"   = ep."earliest_pub_date"
)

SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM CLAIMS_EARLIEST
ORDER BY "word_ct" DESC NULLS LAST
LIMIT 100;