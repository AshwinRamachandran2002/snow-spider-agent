WITH per_publication AS (
    SELECT
        p."publication_number",
        MAX(
            CASE
                WHEN LOWER(f.value:"text"::STRING) ILIKE '%claim%' THEN 1
                ELSE 0
            END
        ) AS has_word_claim
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."claims_localized") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date"   BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
)
SELECT COUNT(*) AS patent_count
FROM   per_publication
WHERE  has_word_claim = 0;