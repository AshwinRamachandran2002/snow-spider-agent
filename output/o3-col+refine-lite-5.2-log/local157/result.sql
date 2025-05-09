WITH vol AS (
  /* 1. Convert every raw volume string to a pure number                */
  SELECT
      "ticker",
      "market_date",
      CASE
        WHEN "volume" = '-'        THEN 0
        WHEN "volume" LIKE '%K'    THEN CAST(REPLACE("volume",'K','') AS REAL)*1000
        WHEN "volume" LIKE '%M'    THEN CAST(REPLACE("volume",'M','') AS REAL)*1000000
        WHEN "volume" LIKE '%B'    THEN CAST(REPLACE("volume",'B','') AS REAL)*1000000000
        ELSE CAST("volume" AS REAL)
      END AS "volume_num"
  FROM "bitcoin_prices"
  WHERE "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
),
non_zero AS (
  /* 2. Keep only non‑zero rows and give them an increasing row number   */
  SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY "ticker" ORDER BY "market_date") AS rn
  FROM vol
  WHERE "volume_num" > 0
),
paired AS (
  /* 3. Pair each row with the previous non‑zero row for the same ticker */
  SELECT
      n1."ticker",
      n1."market_date",
      n1."volume_num" AS current_volume,
      n2."volume_num" AS prev_volume
  FROM non_zero n1
  LEFT JOIN non_zero n2
         ON n1."ticker" = n2."ticker"
        AND n1.rn       = n2.rn + 1
)
SELECT
    "ticker",
    "market_date",
    ROUND( (current_volume - prev_volume) * 100.0 / prev_volume , 2) AS pct_change_volume
FROM paired
WHERE prev_volume IS NOT NULL
ORDER BY "ticker", "market_date";