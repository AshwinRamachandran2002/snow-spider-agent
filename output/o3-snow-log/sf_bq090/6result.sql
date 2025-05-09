/* Difference in average intrinsic value (LastPx ‒ StrikePrice) between
   “feeling-lucky” and “momentum” strategies for LONG-side trades */
SELECT 
    ROUND(
        AVG(CASE WHEN pid.value:"PartyID"::STRING ILIKE '%lucky%' 
                 THEN t."LastPx" - t."StrikePrice" END)
      - AVG(CASE WHEN pid.value:"PartyID"::STRING ILIKE '%momo%'  
                 THEN t."LastPx" - t."StrikePrice" END)
    , 4) AS "AVG_INTRINSIC_VALUE_DIFF_LUCKY_MINUS_MOMENTUM"
FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT"  t,
     LATERAL FLATTEN(input => t."Sides") f,
     LATERAL FLATTEN(input => f.value:"PartyIDs") pid
WHERE f.value:"Side"::STRING ILIKE '%LONG%';