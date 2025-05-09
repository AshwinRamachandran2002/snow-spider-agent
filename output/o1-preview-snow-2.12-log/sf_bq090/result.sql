SELECT
  ROUND(
    ABS(
      AVG(CASE WHEN p.value:"PartyID"::STRING LIKE 'LUCKY%'
               THEN t."LastPx" - t."StrikePrice"
          END) -
      AVG(CASE WHEN p.value:"PartyID"::STRING LIKE 'MOMO%'
               THEN t."LastPx" - t."StrikePrice"
          END)
    ), 4) AS "higher"
FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
     LATERAL FLATTEN(input => t."Sides") f,
     LATERAL FLATTEN(input => f.value:"PartyIDs") p
WHERE f.value:"Side"::STRING = 'LONG';