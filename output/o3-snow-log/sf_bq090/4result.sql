/* How much higher the average intrinsic value is for "feeling-lucky"
   versus "momentum" strategies among LONG-side trades               */
WITH long_side_trades AS (
    SELECT
        LOWER(
            COALESCE(
                f.value:"Strategy"::STRING,
                f.value:"strategy"::STRING,
                f.value:"STRATEGY"::STRING
            )
        )                                            AS strategy_name,
        (t."StrikePrice" - t."LastPx")              AS intrinsic_value
    FROM CYMBAL_INVESTMENTS.CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
         LATERAL FLATTEN(input => t."Sides") f
    WHERE f.value:"Side"::STRING = 'LONG'
),
strategy_avgs AS (
    SELECT
        strategy_name,
        AVG(intrinsic_value) AS avg_intrinsic_value
    FROM long_side_trades
    WHERE strategy_name IN ('feeling-lucky', 'momentum')
    GROUP BY strategy_name
)
SELECT
    ROUND(
        MAX(CASE WHEN strategy_name = 'feeling-lucky' THEN avg_intrinsic_value END) -
        MAX(CASE WHEN strategy_name = 'momentum'     THEN avg_intrinsic_value END),
        4
    ) AS avg_intrinsic_value_difference
FROM strategy_avgs;