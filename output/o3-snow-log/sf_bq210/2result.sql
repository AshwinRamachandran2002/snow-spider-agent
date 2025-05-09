-- Number of U.S. patents (kind code “B2”) granted 2008-01-01 through 2018-12-31
-- whose claim texts NEVER contain the word “claim”
SELECT
    COUNT(*) AS "patents_without_word_claim"
FROM (
    SELECT
        p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p
         , LATERAL FLATTEN (INPUT => p."claims_localized") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date" BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
    HAVING SUM(
              CASE
                  WHEN LOWER(f.value:"text"::STRING) LIKE '%claim%' THEN 1
                  ELSE 0
              END
           ) = 0
) q;