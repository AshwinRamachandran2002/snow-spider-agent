WITH english_claims AS (
    SELECT
        p."publication_number",
        LISTAGG(f.value:"text"::STRING, ' ') AS "full_claims"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."claims_localized") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'
      AND p."grant_date" BETWEEN 20080101 AND 20181231
      AND f.value:"language"::STRING = 'en'
    GROUP BY p."publication_number"
)
SELECT
    COUNT(*) AS "us_b2_no_claim_word"
FROM english_claims
WHERE "full_claims" NOT ILIKE '%claim%';