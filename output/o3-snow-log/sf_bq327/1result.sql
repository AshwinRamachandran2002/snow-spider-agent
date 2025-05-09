SELECT 
    COUNT(*) AS "zero_value_count"
FROM 
    WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
WHERE 
    "country_code" = 'RUS'          -- Russia
    AND "value" = 0                 -- value equal to 0 (NULLs automatically excluded)
;