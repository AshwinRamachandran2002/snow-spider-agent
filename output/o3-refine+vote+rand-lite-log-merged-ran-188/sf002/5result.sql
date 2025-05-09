WITH insured_pct AS (   -- % of deposits that are insured (quarter-end)
    SELECT
        t."ID_RSSD",
        t."VALUE" AS insured_ratio          -- 0–1 ratio (unit = Percent)
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES   a
      ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
      AND a."UNIT" = 'Percent'
      AND t."DATE" = '2022-12-31'
),
total_assets AS (       -- total asset size at the same date
    SELECT
        t."ID_RSSD",
        t."VALUE" AS assets_usd
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES   a
      ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" ILIKE '%Total Assets%'
      AND t."DATE" = '2022-12-31'
),
bank_level AS (         -- merge insured % and assets
    SELECT
        i."ID_RSSD",
        MIN(i.insured_ratio) AS insured_ratio,   -- duplicates (if any) have same value
        MAX(a.assets_usd)    AS assets_usd
    FROM insured_pct i
    JOIN total_assets a ON a."ID_RSSD" = i."ID_RSSD"
    GROUP BY i."ID_RSSD"
),
with_names AS (         -- add bank names & filters
    SELECT
        e."NAME"                                        AS bank_name,
        (1 - b.insured_ratio) * 100                     AS uninsured_asset_percent,
        b.assets_usd
    FROM bank_level b
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
      ON e."ID_RSSD" = b."ID_RSSD"
    WHERE e."IS_ACTIVE" = TRUE
      AND b.assets_usd > 10000000000                    -- > $10B
)
SELECT
    bank_name,
    ROUND(uninsured_asset_percent, 2) AS uninsured_asset_percent
FROM with_names
ORDER BY uninsured_asset_percent DESC NULLS LAST
LIMIT 10;