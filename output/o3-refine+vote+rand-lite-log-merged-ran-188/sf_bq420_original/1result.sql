/*  Top‑5 U.S. patents granted 2010‑2023
    ranked by total words in the granted claims                       */

WITH granted_pubs AS (                       -- 1. U.S. grants, 2010‑2023
    SELECT
        p."application_number",
        p."publication_number"                    AS grant_pub_number,
        p."publication_date"                      AS grant_date,
        REGEXP_SUBSTR(
            p."publication_number",
            'US-([0-9]+)-',                       -- extract digits of patent #
            1, 1, 'i', 1)                         AS patent_number
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         LIKE 'B%'         -- granted patent docs
      AND p."publication_date" BETWEEN 20100101 AND 20231231
),

first_app_pub AS (                            -- 2. earliest U.S. pre‑grant pub
    SELECT
        q."application_number",
        q."publication_number"  AS first_pub_number,
        q."publication_date"    AS first_pub_date
    FROM (
        SELECT
            p."application_number",
            p."publication_number",
            p."publication_date",
            ROW_NUMBER() OVER (PARTITION BY p."application_number"
                               ORDER BY p."publication_date") AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
        WHERE p."country_code" = 'US'
          AND p."kind_code"    LIKE 'A%'         -- pre‑grant publications
    ) q
    WHERE q.rn = 1
),

claim_stats AS (                              -- 3. word‑count of granted claims
    SELECT
        pcs."pat_no"                AS patent_number,
        TO_NUMBER(pcs."pat_wrd_ct") AS grant_claim_word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS pcs
)

SELECT
    g.patent_number                            AS "PATENT_NUMBER",
    f.first_pub_number                         AS "FIRST_PUBLICATION_NUMBER",
    f.first_pub_date                           AS "FIRST_PUBLICATION_DATE",
    cs.grant_claim_word_count                  AS "GRANT_CLAIM_WORD_COUNT",
    g.grant_date                               AS "GRANT_DATE"
FROM   granted_pubs   g
JOIN   claim_stats    cs  ON cs.patent_number      = g.patent_number
JOIN   first_app_pub  f   ON f."application_number" = g."application_number"
ORDER  BY
       cs.grant_claim_word_count DESC NULLS LAST,
       g.patent_number
LIMIT  5;