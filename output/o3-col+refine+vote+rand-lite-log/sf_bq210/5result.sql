-- Count of U.S. B2 patents (granted 2008-2018) whose claim texts never include the word “claim”
SELECT COUNT(*) AS "us_b2_no_claim_word_2008_2018"
FROM (
    SELECT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."claims_localized", outer => TRUE) f
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'
      AND p."grant_date" BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
    HAVING SUM(
             CASE
                 WHEN COALESCE(f.value:"text"::STRING, '') ILIKE '%claim%'
                 THEN 1 ELSE 0
             END
           ) = 0
) ;