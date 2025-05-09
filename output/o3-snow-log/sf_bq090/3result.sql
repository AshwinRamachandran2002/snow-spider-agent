WITH sides_flat AS (
    SELECT
        t."TradeReportID",
        (t."LastPx" - t."StrikePrice")                         AS intrinsic_value,
        LOWER(p.value:"PartyID"::STRING)                       AS party_id,
        f.value:"Side"::STRING                                 AS side_flag
    FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
         LATERAL FLATTEN(input => t."Sides")                f,
         LATERAL FLATTEN(input => f.value:"PartyIDs")       p
), avg_by_strategy AS (
    SELECT
        AVG(CASE WHEN party_id ILIKE 'predict%' AND side_flag ILIKE '%LONG%' THEN intrinsic_value END)
            AS avg_intrinsic_feeling_lucky_long,
        AVG(CASE WHEN party_id ILIKE 'momo%'    AND side_flag ILIKE '%LONG%' THEN intrinsic_value END)
            AS avg_intrinsic_momentum_long
    FROM sides_flat
)
SELECT
    avg_intrinsic_feeling_lucky_long
  - avg_intrinsic_momentum_long  AS intrinsic_value_diff_feeling_lucky_vs_momentum_long
FROM avg_by_strategy;