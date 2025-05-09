WITH independent_claims AS (   -- 1) all independent patent-claims with a word count
    SELECT
        "pat_no",
        "claim_no",
        TO_NUMBER("word_ct")        AS word_ct
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),

matched_pubs AS (               -- 2) attach the DOCDB publication number supplied by the MATCH table
    SELECT
        ic."pat_no",
        ic."claim_no",
        ic.word_ct,
        m."publication_number"
    FROM independent_claims        ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH  m
          ON m."pat_no" = ic."pat_no"
),

pub_with_dates AS (             -- 3) bring in application number & date; keep earliest pub. per application
    SELECT
        mp."pat_no",
        mp."claim_no",
        mp.word_ct,
        p."publication_number",
        p."application_number",
        p."publication_date",
        ROW_NUMBER() OVER (PARTITION BY p."application_number"
                           ORDER BY       p."publication_date" ASC) AS pub_rank
    FROM matched_pubs                        mp
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS  p
          ON p."publication_number" = mp."publication_number"
)

-- 4) top 100 longest independent claims, reporting the earliest publication for each application
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    word_ct
FROM pub_with_dates
WHERE pub_rank = 1
ORDER BY word_ct DESC NULLS LAST
LIMIT 100;