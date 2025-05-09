WITH birth_rate_80s AS (
    SELECT 
        "country_code",
        AVG("value") AS avg_birth_rate
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
    WHERE 
        "indicator_code" = 'SP.DYN.CBRT.IN'
        AND "year" BETWEEN 1980 AND 1989
        AND "value" IS NOT NULL
    GROUP BY 
        "country_code"
)

SELECT
    cs."region",
    cs."short_name"      AS country,
    ROUND(br.avg_birth_rate, 4) AS avg_crude_birth_rate_1980s
FROM birth_rate_80s br
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
      ON br."country_code" = cs."country_code"
WHERE 
    cs."income_group" = 'High income'
    AND cs."region" IS NOT NULL
QUALIFY 
    ROW_NUMBER() OVER (
        PARTITION BY cs."region"
        ORDER BY br.avg_birth_rate DESC NULLS LAST
    ) = 1
ORDER BY 
    cs."region";