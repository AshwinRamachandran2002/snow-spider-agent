/*  Top‑5 U.S. patents granted 2010‑2023 ranked by the total
    word‑count of their granted claims.
    (PAIR examination data not available, so §101 rejection
     filter cannot be applied; FIRST_OFFICE_ACTION_DATE is NULL). */

WITH granted_claim_words AS (           -- total words in granted claims
    SELECT
        pcs."pat_no"                                    AS "PATENT_NUMBER",
        SUM(CAST(pcs."word_ct" AS INT))::INT            AS "GRANTED_CLAIMS_WORDS"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    GROUP BY pcs."pat_no"
),

us_grants_2010_2023 AS (                -- U.S. grants within time window
    SELECT
        pub."publication_number"   AS "PUBLICATION_NUMBER",
        pub."application_number"   AS "APPLICATION_NUMBER",
        pub."publication_date"     AS "PUBLICATION_DATE",
        pub."grant_date"           AS "GRANT_DATE",
        REGEXP_REPLACE(pub."publication_number",
                       'US-([^-]+)-B.*','\\1')         AS "PATENT_NUMBER"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS pub
    WHERE pub."country_code" = 'US'
      AND pub."kind_code" LIKE 'B%'                    -- granted kinds
      AND pub."grant_date" BETWEEN 20100101 AND 20231231
),

earliest_pub AS (                       -- first publication date per application
    SELECT
        "APPLICATION_NUMBER",
        MIN("PUBLICATION_DATE") AS "FIRST_PUBLICATION_DATE"
    FROM us_grants_2010_2023
    GROUP BY "APPLICATION_NUMBER"
),

first_pub_number AS (                   -- first publication number per application
    SELECT
        g."APPLICATION_NUMBER",
        g."PUBLICATION_NUMBER" AS "FIRST_PUBLICATION_NUMBER"
    FROM us_grants_2010_2023 g
    JOIN earliest_pub e
      ON e."APPLICATION_NUMBER"     = g."APPLICATION_NUMBER"
     AND e."FIRST_PUBLICATION_DATE" = g."PUBLICATION_DATE"
)

SELECT
    g."PATENT_NUMBER"                  AS "PATENT_NO",
    fp."FIRST_PUBLICATION_NUMBER"      AS "FIRST_PUBLICATION_NO",
    e."FIRST_PUBLICATION_DATE",
    gc."GRANTED_CLAIMS_WORDS",
    g."GRANT_DATE",
    NULL AS "FIRST_OFFICE_ACTION_DATE"   -- unavailable in current catalog
FROM us_grants_2010_2023 g
JOIN granted_claim_words gc
  ON gc."PATENT_NUMBER" = g."PATENT_NUMBER"
JOIN earliest_pub       e
  ON e."APPLICATION_NUMBER" = g."APPLICATION_NUMBER"
JOIN first_pub_number   fp
  ON fp."APPLICATION_NUMBER" = g."APPLICATION_NUMBER"
QUALIFY ROW_NUMBER() OVER (PARTITION BY g."PATENT_NUMBER"
                           ORDER BY gc."GRANTED_CLAIMS_WORDS" DESC) = 1
ORDER BY gc."GRANTED_CLAIMS_WORDS" DESC NULLS LAST,
         g."PATENT_NUMBER"
LIMIT 5;