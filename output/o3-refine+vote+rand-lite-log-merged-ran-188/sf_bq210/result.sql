WITH base AS (
    SELECT 
        "publication_number",
        "claims_localized"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20080101 AND 20181231
      AND "claims_localized" IS NOT NULL
), claims AS (
    SELECT
        b."publication_number",
        LOWER( fl.value:"text"::string )            AS claim_text
    FROM base b,
         LATERAL FLATTEN( INPUT => b."claims_localized" ) fl
)
SELECT COUNT( DISTINCT "publication_number" ) AS num_us_b2_grants_without_word_claim
FROM (
    SELECT 
        "publication_number"
    FROM claims
    GROUP BY "publication_number"
    HAVING SUM( CASE WHEN claim_text LIKE '%claim%' THEN 1 ELSE 0 END ) = 0
) t;