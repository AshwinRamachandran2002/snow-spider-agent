/*  Count distinct U.S. patents (kind_code like ‘B2’) that were granted
    between 2008-01-01 and 2018-12-31 and have at least one individual claim
    whose text does NOT contain the substring “claim” (case-insensitive).  */
WITH flattened_claims AS (
    SELECT
        p."publication_number",
        /* flag: 1 if this claim text contains the word “claim”, else 0 */
        CASE
            WHEN f.value:"text"::STRING ILIKE '%claim%' THEN 1
            ELSE 0
        END                                             AS "has_word"
    FROM  PATENTS.PATENTS.PUBLICATIONS  p,
          LATERAL FLATTEN (INPUT => p."claims_localized") f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    ILIKE '%B2'
      AND p."grant_date"  BETWEEN 20080101 AND 20181231
)
SELECT COUNT(*) AS "us_b2_2008_2018_with_claim_without_word"
FROM (
         /* keep the patent if at least one of its claims lacks the word */
         SELECT  "publication_number"
         FROM    flattened_claims
         GROUP BY "publication_number"
         HAVING  MIN("has_word") = 0      -- ⇒ at least one 0 among the claims
     ) AS eligible;