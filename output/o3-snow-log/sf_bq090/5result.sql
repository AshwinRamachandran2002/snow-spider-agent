SELECT
    ROUND(
        AVG(CASE 
                WHEN LOWER(pid.value:"PartyID"::STRING) LIKE '%lucky%' 
                THEN ("LastPx" - "StrikePrice") 
            END)
      -
        AVG(CASE 
                WHEN LOWER(pid.value:"PartyID"::STRING) LIKE '%momo%' 
                  OR LOWER(pid.value:"PartyID"::STRING) LIKE '%momentum%' 
                THEN ("LastPx" - "StrikePrice") 
            END)
    , 4) AS "difference_feeling_lucky_minus_momentum"
FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
     LATERAL FLATTEN(input => t."Sides")            f,
     LATERAL FLATTEN(input => f.value:"PartyIDs")   pid
WHERE f.value:"Side"::STRING = 'LONG'
  AND (
        LOWER(pid.value:"PartyID"::STRING) LIKE '%lucky%' 
     OR LOWER(pid.value:"PartyID"::STRING) LIKE '%momo%' 
     OR LOWER(pid.value:"PartyID"::STRING) LIKE '%momentum%'
  );