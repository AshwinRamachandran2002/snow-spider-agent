SELECT
    s."stprba" AS State,
    ROUND(SUM(
        CASE
            WHEN qs."units" ILIKE '%thousand%' THEN qs."value" * 1e3
            WHEN qs."units" ILIKE '%million%' THEN qs."value" * 1e6
            WHEN qs."units" ILIKE '%billion%' THEN qs."value" * 1e9
            ELSE qs."value"
        END
    ) / 1e9, 4) AS Highest_Annual_Revenue_Billions
FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.QUICK_SUMMARY qs
JOIN SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.SUBMISSION s
  ON qs."central_index_key" = s."central_index_key"
WHERE s."countryba" = 'US'
  AND qs."fiscal_year" = 2016
  AND qs."number_of_quarters" = 4
  AND s."stprba" IS NOT NULL
  AND qs."value" > 0
  AND qs."measure_tag" IN (
    SELECT MEASURE_TAG
    FROM SEC_QUARTERLY_FINANCIALS.SEC_QUARTERLY_FINANCIALS.MEASURE_TAG
    WHERE TAG_LABEL ILIKE '%Revenue%' OR TAG_LABEL ILIKE '%Sales%'
  )
GROUP BY s."stprba"
ORDER BY Highest_Annual_Revenue_Billions DESC NULLS LAST
LIMIT 1;