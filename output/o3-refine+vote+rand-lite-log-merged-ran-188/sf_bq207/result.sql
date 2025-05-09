WITH independent_claims AS (      -- 1. claims flagged as independent
    SELECT
        "pat_no",
        "claim_no",
        CAST("word_ct" AS INTEGER) AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS"
    WHERE "ind_flg" = '1'
),

claims_with_pubnum AS (          -- 2. add publication numbers via MATCH
    SELECT
        ic."pat_no",
        ic."claim_no",
        ic."word_ct",
        m."publication_number"
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH" m
      ON ic."pat_no" = m."pat_no"
),

claims_with_pub AS (            -- 3. bring in application numbers & dates
    SELECT
        cp."pat_no",
        cp."claim_no",
        cp."word_ct",
        pub."publication_number",
        pub."application_number",
        pub."publication_date"
    FROM claims_with_pubnum cp
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS" pub
      ON cp."publication_number" = pub."publication_number"
),

earliest_pub_per_app AS (       -- 4. find earliest publication per application
    SELECT
        "application_number",
        MIN("publication_date") AS "earliest_pub_date"
    FROM claims_with_pub
    GROUP BY "application_number"
),

earliest_claim_pubs AS (        -- 5. keep only those earliest publications
    SELECT
        cwp.*
    FROM claims_with_pub  cwp
    JOIN earliest_pub_per_app e
      ON cwp."application_number" = e."application_number"
     AND cwp."publication_date"  = e."earliest_pub_date"
)

-- 6. top-100 longest independent claims (earliest pub per application)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM earliest_claim_pubs
ORDER BY "word_ct" DESC NULLS LAST
LIMIT 100;