-- Count distinct U.S. B2 patents (granted 2008-2018) whose claim text never contains the word “claim”
SELECT COUNT(DISTINCT p."publication_number") AS patent_count_no_word
FROM   PATENTS.PATENTS.PUBLICATIONS               p,
       LATERAL FLATTEN(input => p."claims_localized") f
WHERE  p."country_code" = 'US'
  AND  p."kind_code"    = 'B2'
  AND  p."grant_date" BETWEEN 20080101 AND 20181231
  AND  LOWER(f.value:"text"::STRING) NOT ILIKE '%claim%';