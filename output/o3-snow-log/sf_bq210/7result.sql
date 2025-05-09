-- Count US-B2 patents (granted 2008-01-01 to 2018-12-31) whose claims never contain the word “claim”
SELECT COUNT(*) AS "count_patents_no_claim_word"
FROM (
    SELECT
        p."publication_number",
        MAX(
            CASE
                WHEN LOWER(COALESCE(f.value:"text"::STRING, '')) LIKE '%claim%' THEN 1
                ELSE 0
            END
        ) AS "has_claim_word"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"  p,
         LATERAL FLATTEN(input => p."claims_localized", OUTER => TRUE) f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date"  BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
) q
WHERE q."has_claim_word" = 0;