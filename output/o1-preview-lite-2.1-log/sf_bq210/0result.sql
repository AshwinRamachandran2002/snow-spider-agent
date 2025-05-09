SELECT COUNT(*) AS "number_of_patents"
FROM (
    SELECT t."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."claims_localized") f
    WHERE t."country_code" = 'US'
        AND t."kind_code" = 'B2'
        AND t."grant_date" BETWEEN 20080101 AND 20181231
    GROUP BY t."publication_number"
    HAVING SUM(CASE WHEN f.value:"text"::STRING ILIKE '%claim%' THEN 1 ELSE 0 END) = 0
) s;