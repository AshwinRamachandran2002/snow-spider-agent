WITH birth_80s AS (
    SELECT
        d."country_code",
        d."country_name",
        AVG(d."value") AS "avg_birth_rate"
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA d
    WHERE d."indicator_code" = 'SP.DYN.CBRT.IN'
      AND d."year" BETWEEN 1980 AND 1989
      AND d."value" IS NOT NULL
    GROUP BY d."country_code", d."country_name"
),
hi_countries AS (
    SELECT
        cs."country_code",
        cs."region"
    FROM WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
    WHERE cs."income_group" = 'High income'
      AND cs."region" IS NOT NULL
)
SELECT
    sub."region",
    sub."country_name",
    ROUND(sub."avg_birth_rate", 4) AS "avg_birth_rate"
FROM (
    SELECT
        hc."region",
        b."country_name",
        b."avg_birth_rate",
        ROW_NUMBER() OVER (
            PARTITION BY hc."region"
            ORDER BY b."avg_birth_rate" DESC NULLS LAST
        ) AS rn
    FROM birth_80s b
    JOIN hi_countries hc
      ON b."country_code" = hc."country_code"
) sub
WHERE sub.rn = 1
ORDER BY sub."region";