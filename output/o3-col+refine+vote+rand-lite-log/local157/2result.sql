WITH vols AS (
  SELECT
    "ticker",
    "market_date",
    CASE
      WHEN "volume" = '-'           THEN 0
      WHEN "volume" LIKE '%K'       THEN CAST(REPLACE("volume", 'K', '') AS REAL) * 1000
      WHEN "volume" LIKE '%M'       THEN CAST(REPLACE("volume", 'M', '') AS REAL) * 1000000
      ELSE CAST("volume" AS REAL)
    END AS "volume_num"
  FROM "bitcoin_prices"
  WHERE "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
),
lagged AS (
  SELECT
    v1."ticker",
    v1."market_date",
    v1."volume_num",
    (
      SELECT v2."volume_num"
      FROM vols v2
      WHERE v2."ticker" = v1."ticker"
        AND v2."market_date" < v1."market_date"
        AND v2."volume_num" > 0
      ORDER BY v2."market_date" DESC
      LIMIT 1
    ) AS "prev_non_zero_volume"
  FROM vols v1
),
pct_change AS (
  SELECT
    "ticker",
    "market_date",
    "volume_num",
    "prev_non_zero_volume",
    CASE
      WHEN "prev_non_zero_volume" IS NULL OR "prev_non_zero_volume" = 0 THEN NULL
      ELSE ROUND(
             100.0 * ("volume_num" - "prev_non_zero_volume") / "prev_non_zero_volume",
             4
           )
    END AS "pct_change_volume"
  FROM lagged
)
SELECT *
FROM pct_change
ORDER BY "ticker", "market_date";