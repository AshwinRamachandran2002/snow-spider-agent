SELECT
    COUNT(DISTINCT p."publication_number") AS "num_us_b2_2008_2018_with_claims_without_word_claim"
FROM
    PATENTS.PATENTS.PUBLICATIONS p,
    LATERAL FLATTEN(INPUT => p."claims_localized") f
WHERE
    p."country_code" = 'US'
    AND p."kind_code"  = 'B2'
    AND p."grant_date" BETWEEN 20080101 AND 20181231
    AND f.value:"text"::STRING NOT ILIKE '%claim%';