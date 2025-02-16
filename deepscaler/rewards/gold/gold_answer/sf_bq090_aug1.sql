-- Task: Compute the average intrinsic value for trades using the feeling-lucky strategy under long-side trades.
SELECT
  ROUND(
    AVG(t."LastPx" - t."StrikePrice"), 4) AS "average_intrinsic_value"
FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
     LATERAL FLATTEN(input => t."Sides") f,
     LATERAL FLATTEN(input => f.value:"PartyIDs") p
WHERE f.value:"Side"::STRING = 'LONG'
  AND p.value:"PartyID"::STRING LIKE 'LUCKY%';