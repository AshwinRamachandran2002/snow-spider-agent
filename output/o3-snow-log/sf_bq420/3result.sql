/*  Top-5 longest-claim U.S. patents granted 2010-2023,
    together with their first-family U.S. publication info          */

WITH grant_claim_len AS (               -- claim length (words) for each patent
    SELECT
        d."pat_no"      AS "pat_no",
        d."pat_wrd_ct"  AS "granted_claim_words"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_DOCUMENT_STATS" d
),

us_family_pubs AS (                     -- all U.S. family publications
    SELECT
        m."pat_no",
        p."publication_number",
        p."publication_date",
        p."grant_date"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"   m
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"     p
          ON m."publication_number" = p."publication_number"
    WHERE p."country_code" = 'US'
      AND p."grant_date" BETWEEN 20100101 AND 20231231
),

first_pub_per_pat AS (                  -- earliest U.S. publication per patent
    SELECT
        "pat_no",
        MIN_BY("publication_number", "publication_date")  AS "first_publication_number",
        MIN("publication_date")                           AS "first_publication_date",
        MIN("grant_date")                                 AS "us_grant_date"
    FROM us_family_pubs
    GROUP BY "pat_no"
)

SELECT
    g."pat_no"                       AS "us_patent_number",
    f."first_publication_number",
    f."first_publication_date",
    g."granted_claim_words",
    f."us_grant_date"
FROM grant_claim_len      g
JOIN first_pub_per_pat    f  ON g."pat_no" = f."pat_no"
ORDER BY g."granted_claim_words" DESC NULLS LAST
LIMIT 5;