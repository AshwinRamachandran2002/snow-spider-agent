WITH calendar AS (
    /* Build a month list from 2008-01 to 2022-12 (180 rows) */
    SELECT TO_CHAR(DATEADD(month, seq4(), DATE '2008-01-01'), 'YYYYMM') AS "yyyymm"
    FROM   TABLE(GENERATOR(ROWCOUNT => 180))
),
iot_counts AS (
    /* Count distinct U.S. publications whose abstract mentions “internet of things” */
    SELECT  TO_CHAR(TO_DATE(TO_CHAR(p."filing_date"), 'YYYYMMDD'), 'YYYYMM') AS "yyyymm",
            COUNT(DISTINCT p."publication_number")                            AS "pub_count"
    FROM    PATENTS.PATENTS.PUBLICATIONS p,
            LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE   p."country_code" = 'US'
      AND   p."filing_date" BETWEEN 20080101 AND 20221231
      AND   f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY 1
)
SELECT   c."yyyymm",
         COALESCE(i."pub_count", 0) AS "iot_pub_count"
FROM     calendar c
LEFT JOIN iot_counts i
       ON c."yyyymm" = i."yyyymm"
ORDER BY c."yyyymm";