SELECT 
    COUNT(DISTINCT "indicator_code") AS "zero_debt_indicators_count"
FROM 
    WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
WHERE 
    "country_code" = 'RUS'          -- Russia
    AND "value" = 0                 -- value equal to zero (NULLs automatically excluded)
;