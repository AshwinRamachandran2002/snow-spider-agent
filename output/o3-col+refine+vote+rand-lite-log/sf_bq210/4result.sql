SELECT COUNT(DISTINCT p."publication_number") AS "patent_count"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(INPUT => p."claims_localized") f
WHERE p."country_code"   = 'US'          -- U​S patents
  AND p."kind_code"      = 'B2'          -- granted (B2)
  AND p."publication_date" BETWEEN 20080101 AND 20181231  -- 2008-2018 grants
  AND LOWER(f.value:"language"::STRING) = 'en'            -- English claims
  AND f.value:"text"::STRING NOT ILIKE '%claim%'          -- claim text lacks 'claim'
;