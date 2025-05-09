/*---------------------------------------------------------------
Top‑5 U.S. patents granted between 2010‑01‑01 and 2023‑12‑31
having the longest independent‑claim word counts.

Because the provided PATENTS_USPTO data set does not include
prosecution‑history tables (e.g., PAIR office‑action records),
the query cannot directly detect “initial §101 rejection with
no allowed claims.”  Instead, it returns:

• first_publication_number  – earliest A‑kind publication
• first_publication_date    – date of that earliest publication
• first_office_action_date  – proxy = earliest non‑null filing_date
                                found in PATENTS.PUBLICATIONS
• filed_claim_length_words  – words in independent granted claims
• grant_date                – date of the B‑kind (grant) publication
----------------------------------------------------------------*/

WITH grant_docs AS (                    -- granted pubs + claim length
    SELECT
        pds."pat_no",
        pds."pat_wrd_ct",
        pub."publication_number"          AS "grant_pub_no",
        pub."publication_date"            AS "grant_date",
        pub."family_id"
    FROM   "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PATENT_DOCUMENT_STATS"  pds
    JOIN   "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."MATCH"                 m
           ON pds."pat_no" = m."pat_no"
    JOIN   "PATENTS_USPTO"."PATENTS"."PUBLICATIONS"                   pub
           ON pub."publication_number" = m."publication_number"
    WHERE  pub."country_code" = 'US'
      AND  pub."kind_code" ILIKE 'B%'          -- grant (B1, B2, …)
      AND  pub."publication_date" BETWEEN 20100101 AND 20231231
),
first_app_pub AS (                      -- earliest A‑kind pub / family
    SELECT
        "family_id",
        "publication_number" AS "first_pub_no",
        "publication_date"   AS "first_pub_date"
    FROM (
        SELECT
            "family_id",
            "publication_number",
            "publication_date",
            ROW_NUMBER() OVER (PARTITION BY "family_id"
                               ORDER BY "publication_date") AS rn
        FROM "PATENTS_USPTO"."PATENTS"."PUBLICATIONS"
        WHERE "kind_code" ILIKE 'A%'        -- application publication
    )
    WHERE rn = 1
),
first_oa_proxy AS (                     -- proxy for 1st office action
    SELECT
        "family_id",
        MIN("filing_date") AS "first_oa_date"
    FROM "PATENTS_USPTO"."PATENTS"."PUBLICATIONS"
    WHERE "filing_date" IS NOT NULL 
          AND "filing_date" > 0
    GROUP BY "family_id"
)

SELECT
    fap."first_pub_no"                     AS first_publication_number,
    TO_VARCHAR(fap."first_pub_date")       AS first_publication_date,
    TO_VARCHAR(foa."first_oa_date")        AS first_office_action_date,
    gd."pat_wrd_ct"                        AS filed_claim_length_words,
    TO_VARCHAR(gd."grant_date")            AS grant_date
FROM   grant_docs       gd
JOIN   first_app_pub    fap ON fap."family_id" = gd."family_id"
LEFT  JOIN first_oa_proxy foa ON foa."family_id" = gd."family_id"
ORDER  BY gd."pat_wrd_ct" DESC NULLS LAST,
          gd."grant_date"
LIMIT 5;