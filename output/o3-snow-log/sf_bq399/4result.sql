WITH cbr AS (  -- Crude birth-rate observations in the 1980s
    SELECT 
        d."country_code",
        d."country_name",
        d."value"      AS "birth_rate",
        d."year"
    FROM WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA" d
    WHERE d."indicator_code" = 'SP.DYN.CBRT.IN'
      AND d."year" BETWEEN 1980 AND 1989
      AND d."value" IS NOT NULL
), 
  
avg_cbr AS (   -- Average 1980-89 crude birth-rate per high-income country & region
    SELECT
        cbr."country_code",
        cs."region",
        cbr."country_name",
        AVG(cbr."birth_rate") AS "avg_birth_rate"
    FROM cbr
    JOIN WORLD_BANK.WORLD_BANK_WDI."COUNTRY_SUMMARY" cs
          ON cs."country_code" = cbr."country_code"
    WHERE LOWER(cs."income_group") = 'high income'
    GROUP BY 
        cbr."country_code",
        cs."region",
        cbr."country_name"
), 
  
ranked AS (    -- Rank countries by average rate within each region
    SELECT
        "region",
        "country_name",
        ROUND("avg_birth_rate", 4) AS "avg_birth_rate",
        ROW_NUMBER() OVER (PARTITION BY "region" 
                           ORDER BY "avg_birth_rate" DESC NULLS LAST) AS rn
    FROM avg_cbr
)
  
SELECT
    "region",
    "country_name"  AS "high_income_country",
    "avg_birth_rate"
FROM ranked
WHERE rn = 1        -- Highest average crude birth-rate in each region
ORDER BY "region";