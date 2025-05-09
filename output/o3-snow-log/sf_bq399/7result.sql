/* 1)  Get crude-birth-rate observations for 1980-1989
   2)  Compute every high-income country’s average for the decade
   3)  Per World-Bank region, keep the country with the highest average  */
WITH birth_80s AS (          -- crude birth-rate records in the 1980s
    SELECT  d."country_code",
            d."country_name",
            d."value"              AS "birth_rate"
    FROM    WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA d
    WHERE   d."indicator_code" = 'SP.DYN.CBRT.IN'
      AND   d."year" BETWEEN 1980 AND 1989
      AND   d."value" IS NOT NULL
), avg_birth AS (            -- average 1980-89 crude birth-rate per country
    SELECT  b."country_code",
            b."country_name",
            AVG(b."birth_rate")   AS "avg_birth_rate"
    FROM    birth_80s b
    GROUP BY b."country_code",
             b."country_name"
), high_income AS (          -- keep only high-income economies and their region
    SELECT  c."country_code",
            c."region"
    FROM    WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY c
    WHERE   c."income_group" ILIKE 'High income%'
)
SELECT  h."region",
        a."country_name",
        ROUND(a."avg_birth_rate", 4)  AS "average_crude_birth_rate"
FROM    avg_birth     a
JOIN    high_income   h  ON a."country_code" = h."country_code"
QUALIFY ROW_NUMBER() OVER (PARTITION BY h."region"
                           ORDER BY a."avg_birth_rate" DESC NULLS LAST) = 1   -- pick top per region
ORDER BY h."region";