WITH TradeData AS (
  SELECT
    ABS(t."LastPx" - t."StrikePrice") AS "IntrinsicValue",
    p.value:"PartyID"::STRING AS "Strategy"
  FROM "CYMBAL_INVESTMENTS"."CYMBAL_INVESTMENTS"."TRADE_CAPTURE_REPORT" t,
       LATERAL FLATTEN(input => t."Sides") f,
       LATERAL FLATTEN(input => f.value:"PartyIDs") p
  WHERE f.value:"Side"::STRING = 'LONG'
)
SELECT
  ROUND(
    ABS(
      (SELECT AVG("IntrinsicValue") FROM TradeData WHERE "Strategy" IN ('LUCKYBTC', 'LUCKYES', 'LUCKYNQ'))
      - (SELECT AVG("IntrinsicValue") FROM TradeData WHERE "Strategy" IN ('MOMOBTC', 'MOMOES', 'MOMONQ'))
    ), 4
  ) AS "higher";