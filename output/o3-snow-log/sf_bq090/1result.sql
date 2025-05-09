SELECT
    AVG(CASE
            WHEN p.value:"PartyID"::STRING ILIKE '%LUCK%' 
            THEN t."LastPx" - t."StrikePrice"
        END)
  - AVG(CASE
            WHEN p.value:"PartyID"::STRING ILIKE '%MOMO%' 
            THEN t."LastPx" - t."StrikePrice"
        END)                                             AS "Delta_Avg_Intrinsic_Value"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
     LATERAL FLATTEN(input => t."Sides")            s,
     LATERAL FLATTEN(input => s.value:"PartyIDs")   p
WHERE s.value:"Side"::STRING ILIKE '%LONG%';