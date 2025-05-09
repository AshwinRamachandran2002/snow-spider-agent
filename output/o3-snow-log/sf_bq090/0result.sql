SELECT  
       AVG(CASE WHEN t."TargetCompID" ILIKE '%LUCKY%' THEN (t."LastPx" - t."StrikePrice") END)
     - AVG(CASE WHEN t."TargetCompID" ILIKE '%MOMO%'  THEN (t."LastPx" - t."StrikePrice") END)
       AS "avg_intrinsic_value_diff_feeling_lucky_vs_momentum"
FROM   "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
       LATERAL FLATTEN(input => t."Sides") f
WHERE  f.value:"Side"::STRING = 'LONG';