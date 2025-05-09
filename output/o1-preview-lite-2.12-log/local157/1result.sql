SELECT
    c.ticker,
    c.market_date,
    ROUND(((c.volume_numeric - p.volume_numeric) / p.volume_numeric) * 100, 4) AS percentage_change_in_volume
FROM
    (
        SELECT
            ticker,
            market_date,
            CASE
                WHEN volume = '-' THEN 0
                WHEN volume LIKE '%K' THEN CAST(REPLACE(volume, 'K', '') AS REAL) * 1000
                WHEN volume LIKE '%M' THEN CAST(REPLACE(volume, 'M', '') AS REAL) * 1000000
                ELSE CAST(volume AS REAL)
            END AS volume_numeric,
            DATE(substr(market_date, 7, 4) || '-' || substr(market_date, 4, 2) || '-' || substr(market_date, 1, 2)) AS parsed_date
        FROM "bitcoin_prices"
    ) c
JOIN
    (
        SELECT
            ticker,
            market_date,
            CASE
                WHEN volume = '-' THEN 0
                WHEN volume LIKE '%K' THEN CAST(REPLACE(volume, 'K', '') AS REAL) * 1000
                WHEN volume LIKE '%M' THEN CAST(REPLACE(volume, 'M', '') AS REAL) * 1000000
                ELSE CAST(volume AS REAL)
            END AS volume_numeric,
            DATE(substr(market_date, 7, 4) || '-' || substr(market_date, 4, 2) || '-' || substr(market_date, 1, 2)) AS parsed_date
        FROM "bitcoin_prices"
    ) p
ON
    c.ticker = p.ticker
    AND c.parsed_date = DATE(p.parsed_date, '+1 day')
    AND p.volume_numeric > 0
WHERE
    c.parsed_date BETWEEN '2021-08-01' AND '2021-08-10'
ORDER BY
    c.ticker,
    c.parsed_date;