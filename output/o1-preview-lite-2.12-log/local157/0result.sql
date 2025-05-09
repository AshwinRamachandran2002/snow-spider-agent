SELECT
    t1."ticker",
    t1."market_date",
    ROUND(((t1."volume_num" - t2."volume_num") / t2."volume_num") * 100, 4) AS "percentage_change_in_volume"
FROM
    (
        SELECT
            "ticker",
            "market_date",
            CAST(
                CASE
                    WHEN "volume" = '-' THEN '0'
                    WHEN "volume" LIKE '%K' THEN REPLACE("volume", 'K', '') * 1000
                    WHEN "volume" LIKE '%M' THEN REPLACE("volume", 'M', '') * 1000000
                    ELSE "volume"
                END AS REAL
            ) AS "volume_num",
            DATE(
                SUBSTR("market_date", 7, 4) || '-' ||
                SUBSTR("market_date", 4, 2) || '-' ||
                SUBSTR("market_date", 1, 2)
            ) AS "parsed_date"
        FROM
            "bitcoin_prices"
    ) AS t1
JOIN
    (
        SELECT
            "ticker",
            "market_date",
            CAST(
                CASE
                    WHEN "volume" = '-' THEN '0'
                    WHEN "volume" LIKE '%K' THEN REPLACE("volume", 'K', '') * 1000
                    WHEN "volume" LIKE '%M' THEN REPLACE("volume", 'M', '') * 1000000
                    ELSE "volume"
                END AS REAL
            ) AS "volume_num",
            DATE(
                SUBSTR("market_date", 7, 4) || '-' ||
                SUBSTR("market_date", 4, 2) || '-' ||
                SUBSTR("market_date", 1, 2)
            ) AS "parsed_date"
        FROM
            "bitcoin_prices"
    ) AS t2
ON
    t1."ticker" = t2."ticker" AND
    t2."parsed_date" = DATE(t1."parsed_date", '-1 day')
WHERE
    t1."parsed_date" BETWEEN '2021-08-01' AND '2021-08-10' AND
    t2."volume_num" > 0
ORDER BY
    t1."ticker",
    t1."parsed_date";