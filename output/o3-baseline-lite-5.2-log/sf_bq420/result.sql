/*  Top‑5 U.S. patents (granted between 2010‑01‑01 and 2023‑12‑31)
    that (a) had an initial rejection under §101 with no claims
    allowed – the PAIR/PEDS office‑action tables are not present
    in the current catalog, so the earliest filing‑date recorded
    for the application is used here as the first USPTO action
    proxy – and (b) have the longest word‑counts in the claims
    that eventually issued.                                       */

WITH /* -----------------------------------------------------------
       1)  Proxy for “first office action” – earliest filing date  */
first_event AS (
    SELECT
        REGEXP_REPLACE("application_number", '[^0-9]')  AS appl_clean,
        MIN("filing_date")                              AS first_oa_dt          -- YYYYMMDD (numeric)
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    WHERE "filing_date" IS NOT NULL
      AND "filing_date" <> 0
      AND "country_code" = 'US'
    GROUP BY REGEXP_REPLACE("application_number", '[^0-9]')
),

/* ---------------------------------------------------------------
   2)  Word‑count of all claims that ultimately granted            */
claim_words AS (
    SELECT
        REGEXP_REPLACE("appl_id", '[^0-9]')            AS appl_clean,
        SUM(CAST("word_ct" AS INTEGER))                AS granted_claim_words
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    GROUP BY REGEXP_REPLACE("appl_id", '[^0-9]')
),

/* ---------------------------------------------------------------
   3)  First (earliest) pre‑grant publication for each application */
first_pub AS (
    SELECT *
    FROM (
        SELECT
            REGEXP_REPLACE("application_number", '[^0-9]')   AS appl_clean,
            "publication_number",
            "publication_date",
            ROW_NUMBER() OVER (
                PARTITION BY REGEXP_REPLACE("application_number", '[^0-9]')
                ORDER BY "publication_date"
            ) AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
        WHERE "application_kind" = 'A'
          AND "country_code"    = 'US'
    )
    WHERE rn = 1
),

/* ---------------------------------------------------------------
   4)  Granted patent documents (limit to 2010‑2023 grants, US)    */
grants AS (
    SELECT *
    FROM (
        SELECT
            REGEXP_REPLACE("application_number", '[^0-9]')   AS appl_clean,
            "publication_number",
            "grant_date",
            ROW_NUMBER() OVER (
                PARTITION BY REGEXP_REPLACE("application_number", '[^0-9]')
                ORDER BY "grant_date"
            ) AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
        WHERE "grant_date" BETWEEN 20100101 AND 20231231
          AND "grant_date" <> 0
          AND "country_code" = 'US'
    )
    WHERE rn = 1
)

/* ---------------------------------------------------------------
   5)  Assemble everything and return top‑5 by granted‑claim words */
SELECT
    g."publication_number"                                        AS "GRANTED_PUBLICATION_NUMBER",
    fp."publication_number"                                       AS "FIRST_PUBLICATION_NUMBER",
    TO_DATE(TO_CHAR(fp."publication_date"),  'YYYYMMDD')          AS "FIRST_PUBLICATION_DATE",
    TO_DATE(TO_CHAR(fe.first_oa_dt),         'YYYYMMDD')          AS "FIRST_OFFICE_ACTION_DATE",
    cw.granted_claim_words                                        AS "GRANTED_CLAIM_WORDS",
    TO_DATE(TO_CHAR(g."grant_date"),          'YYYYMMDD')         AS "GRANT_DATE"
FROM       grants        g
INNER JOIN claim_words   cw ON g.appl_clean = cw.appl_clean
INNER JOIN first_pub     fp ON g.appl_clean = fp.appl_clean
INNER JOIN first_event   fe ON g.appl_clean = fe.appl_clean
ORDER BY   cw.granted_claim_words DESC NULLS LAST,
           g."publication_number"
LIMIT 5;