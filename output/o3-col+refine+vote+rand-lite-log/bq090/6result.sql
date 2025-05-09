WITH base AS (
  SELECT
    CASE
      WHEN LOWER(`TargetCompID`) LIKE '%lucky%' THEN 'feeling-lucky'
      WHEN LOWER(`TargetCompID`) LIKE '%momo%'  THEN 'momentum'
    END                                                   AS strategy,
    (`StrikePrice` - `LastPx`) * `Quantity`               AS intrinsic_value
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report`,
       UNNEST(`Sides`) AS s
  WHERE s.Side = 'LONG'
    AND (LOWER(`TargetCompID`) LIKE '%lucky%' OR LOWER(`TargetCompID`) LIKE '%momo%')
)

SELECT
  AVG(CASE WHEN strategy = 'feeling-lucky' THEN intrinsic_value END) -
  AVG(CASE WHEN strategy = 'momentum'      THEN intrinsic_value END) AS diff_avg_intrinsic_value
FROM base;