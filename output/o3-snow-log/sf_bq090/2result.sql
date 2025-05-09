SELECT 
       ROUND(
             AVG(CASE WHEN p.value:"PartyID"::STRING ILIKE '%LUCKY%' 
                      THEN t."LastPx" - t."StrikePrice" END)
           - AVG(CASE WHEN p.value:"PartyID"::STRING ILIKE '%MOMO%' 
                      THEN t."LastPx" - t."StrikePrice" END)
           , 4
       )                                                    AS "avg_intrinsic_value_delta"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS."TRADE_CAPTURE_REPORT" t,
     LATERAL FLATTEN(input => t."Sides")                    s,
     LATERAL FLATTEN(input => s.value:"PartyIDs")           p
WHERE s.value:"Side"::STRING = 'LONG';