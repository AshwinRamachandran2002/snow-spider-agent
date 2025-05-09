SELECT
  ROUND(
    ABS(
      (
        SELECT AVG(t."LastPx" - t."StrikePrice")
        FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
             LATERAL FLATTEN(input => t."Sides") s,
             LATERAL FLATTEN(input => s.value:"PartyIDs") pid
        WHERE s.value:"Side"::STRING = 'LONG' AND pid.value:"PartyID"::STRING = 'PREDICTNQ'
      ) -
      (
        SELECT AVG(t."LastPx" - t."StrikePrice")
        FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
             LATERAL FLATTEN(input => t."Sides") s,
             LATERAL FLATTEN(input => s.value:"PartyIDs") pid
        WHERE s.value:"Side"::STRING = 'LONG' AND pid.value:"PartyID"::STRING = 'MOMOES'
      )
    ), 4
  ) AS "higher";