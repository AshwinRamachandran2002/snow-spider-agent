SELECT COUNT(*) AS "us_b2_no_word_claim_2008_2018"
FROM (
    SELECT  p."publication_number"
    FROM    PATENTS.PATENTS.PUBLICATIONS  p,
            LATERAL FLATTEN ( input => p."claims_localized" ) f
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"    = 'B2'
      AND   p."grant_date" BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
    HAVING  SUM( IFF( LOWER( f.value:"text"::STRING ) ILIKE '%claim%', 1, 0 ) ) = 0
) t;