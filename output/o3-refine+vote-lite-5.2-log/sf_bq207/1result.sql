WITH ind_claims AS (          -- 1. independent claims with word counts
    SELECT
        "pat_no",
        "appl_id",
        "claim_no",
        TO_NUMBER("word_ct")        AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),

claims_pub AS (               -- 2. add DOCDB‑style publication numbers
    SELECT
        ic."pat_no",
        ic."appl_id",
        ic."claim_no",
        ic."word_ct",
        m."publication_number"
    FROM ind_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH" m
          ON ic."pat_no" = m."pat_no"
),

pub_with_dates AS (           -- 3. attach publication metadata
    SELECT
        cp."pat_no",
        cp."appl_id",
        cp."claim_no",
        cp."word_ct",
        p."publication_number",
        p."application_number",
        p."publication_date",
        ROW_NUMBER() OVER (PARTITION BY p."application_number"
                           ORDER BY p."publication_date" ASC) AS rn
    FROM claims_pub cp
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS p
          ON cp."publication_number" = p."publication_number"
)

SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM pub_with_dates
WHERE rn = 1                     -- keep earliest publication per application
ORDER BY "word_ct" DESC NULLS LAST, "publication_number"
LIMIT 100;