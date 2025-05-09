/*  Top-5 longest-claim U.S. patents granted between 2010-01-01 and 2023-12-31  */

WITH us_grants AS (                     -- U.S. grants during the period
    SELECT
        p."publication_number",
        p."publication_date"  AS "first_publication_date",
        p."grant_date"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code"    LIKE 'B%'      -- granted patents (B1/B2/Bn)
      AND p."grant_date"   BETWEEN 20100101 AND 20231231
),

claim_stats AS (                         -- claim-length statistics
    SELECT
        TRY_TO_NUMBER(s."pat_no")     AS "pat_no_num",
        TRY_TO_NUMBER(s."pat_wrd_ct") AS "granted_claim_word_cnt",
        TRY_TO_NUMBER(s."pat_clm_ct") AS "granted_claim_cnt"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS s
),

grant2pub AS (                           -- map patent-number → publication #
    SELECT
        TRY_TO_NUMBER(m."pat_no") AS "pat_no_num",
        m."publication_number"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
),

assembled AS (                           -- merge everything
    SELECT
        g."publication_number"           AS "first_publication_number",
        g."first_publication_date",
        g."grant_date",
        cs."granted_claim_word_cnt",
        cs."granted_claim_cnt"
    FROM us_grants   g
    JOIN grant2pub   mp ON mp."publication_number" = g."publication_number"
    JOIN claim_stats cs ON cs."pat_no_num"         = mp."pat_no_num"
)

SELECT
    "first_publication_number",
    "first_publication_date",
    "grant_date",
    "granted_claim_word_cnt" AS "words_in_granted_claims",
    "granted_claim_cnt"      AS "number_of_granted_claims"
FROM assembled
ORDER BY "granted_claim_word_cnt" DESC NULLS LAST
LIMIT 5;