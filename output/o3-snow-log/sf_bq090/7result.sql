WITH long_side AS (
    SELECT
        f.value:"Strategy"::STRING              AS "STRATEGY",
        t."LastPx" - t."StrikePrice"            AS "INTRINSIC_VALUE"
    FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
         LATERAL FLATTEN(input => t."Sides") f
    WHERE f.value:"Side"::STRING = 'LONG'
)

SELECT
    AVG(CASE WHEN LOWER("STRATEGY") = 'feeling-lucky' THEN "INTRINSIC_VALUE" END)
    -
    AVG(CASE WHEN LOWER("STRATEGY") = 'momentum'      THEN "INTRINSIC_VALUE" END)
        AS "AVG_INTRINSIC_DIFF_FEELING_LUCKY_VS_MOMENTUM"
FROM long_side;