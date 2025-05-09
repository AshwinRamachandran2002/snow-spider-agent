WITH english_claims AS (
    SELECT
        pub."publication_number",
        LISTAGG(LOWER(f.value:"text"::STRING), ' ')
            WITHIN GROUP (ORDER BY f.index) AS "all_claim_text"
    FROM PATENTS.PATENTS.PUBLICATIONS AS pub,
         LATERAL FLATTEN(input => pub."claims_localized") AS f
    WHERE pub."country_code" = 'US'
      AND pub."kind_code"    = 'B2'
      AND pub."grant_date" BETWEEN 20080101 AND 20181231
      AND f.value:"language"::STRING = 'en'
    GROUP BY pub."publication_number"
)
SELECT COUNT(*) AS "patents_without_word_claim"
FROM english_claims
WHERE "all_claim_text" NOT ILIKE '%claim%';