SELECT
    cpc_def."titleFull" AS "Full_Title",
    cpc_group_stats."cpc_group" AS "CPC_Group",
    cpc_group_stats."best_year" AS "Best_Year"
FROM
    (
        SELECT
            "cpc_group",
            "filing_year" AS "best_year"
        FROM
            (
                SELECT
                    "cpc_group",
                    "filing_year",
                    SUM("filing_count" * POWER(0.1, 2016 - "filing_year")) /
                    SUM(POWER(0.1, 2016 - "filing_year")) AS "ema"
                FROM
                    (
                        SELECT
                            LEFT(cpc_code.value:"code"::STRING, 4) AS "cpc_group",
                            EXTRACT(year FROM TRY_TO_DATE("filing_date"::VARCHAR, 'YYYYMMDD')) AS "filing_year",
                            COUNT(*) AS "filing_count"
                        FROM
                            "PATENTS"."PATENTS"."PUBLICATIONS",
                            LATERAL FLATTEN(input => "cpc") cpc_code
                        WHERE
                            "country_code" = 'DE'
                                AND TRY_TO_DATE("grant_date"::VARCHAR, 'YYYYMMDD') BETWEEN '2016-12-01' AND '2016-12-31'
                                AND "grant_date" != 0
                                AND "filing_date" != 0
                        GROUP BY
                            "cpc_group", "filing_year"
                        HAVING
                            "filing_year" IS NOT NULL
                    ) sub
                GROUP BY
                    "cpc_group", "filing_year"
            ) ema_calc
        QUALIFY ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "ema" DESC NULLS LAST) = 1
    ) cpc_group_stats
LEFT JOIN "PATENTS"."PATENTS"."CPC_DEFINITION" cpc_def
    ON cpc_def."symbol" = cpc_group_stats."cpc_group"
ORDER BY
    cpc_group_stats."cpc_group";