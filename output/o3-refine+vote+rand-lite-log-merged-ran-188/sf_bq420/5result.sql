/*  Five U.S. patents granted between 2010-01-01 and 2023-12-31
    with the longest independent-claim word-counts, together with
    their first publication number/date and grant date            */

WITH claim_stats AS (                 -- granted-claim word counts
    SELECT
        s."pat_no",
        s."pat_wrd_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS s
),

pub_links AS (                        -- join claims ↔ publications
    SELECT
        cs."pat_no",
        p."publication_number",
        p."publication_date",
        p."grant_date",
        cs."pat_wrd_ct"
    FROM claim_stats cs
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH  m
         ON m."pat_no" = cs."pat_no"
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS    p
         ON p."publication_number" = m."publication_number"
    WHERE p."country_code" = 'US'
      AND p."grant_date" BETWEEN 20100101 AND 20231231
),

first_pub AS (                        -- earliest publication per grant
    SELECT
        "pat_no",
        MIN_BY("publication_number","publication_date") AS first_pub_no,
        MIN("publication_date")                         AS first_pub_dt,
        MIN("grant_date")                               AS grant_dt,
        MAX("pat_wrd_ct")                               AS pat_wrd_ct
    FROM pub_links
    GROUP BY "pat_no"
)

SELECT
    fp.first_pub_no                                                 AS "first_publication_number",
    TO_DATE(TO_VARCHAR(fp.first_pub_dt),'YYYYMMDD')                 AS "first_publication_date",
    fp."pat_no"                                                     AS "patent_number",
    TO_DATE(TO_VARCHAR(fp.grant_dt)   ,'YYYYMMDD')                  AS "grant_date",
    fp.pat_wrd_ct                                                   AS "granted_claim_word_count"
FROM first_pub fp
ORDER BY fp.pat_wrd_ct DESC NULLS LAST
LIMIT 5;