WITH vols AS (   -- convert the raw volume string into pure units
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "volume" = '-'                    THEN 0
            WHEN RIGHT("volume",1) = 'K'           THEN ROUND(TRY_TO_NUMBER(REPLACE("volume",'K','')),0) * 1000
            WHEN RIGHT("volume",1) = 'M'           THEN ROUND(TRY_TO_NUMBER(REPLACE("volume",'M','')),0) * 1000000
            ELSE TRY_TO_NUMBER("volume")
        END AS "volume_units"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES
    WHERE "market_date" IN (
        '01-08-2021','02-08-2021','03-08-2021','04-08-2021',
        '05-08-2021','06-08-2021','07-08-2021','08-08-2021',
        '09-08-2021','10-08-2021'
    )
),
non_zero AS (    -- keep only non-zero volumes and pull previous non-zero volume
    SELECT
        "ticker",
        "market_date",
        "volume_units",
        LAG("volume_units") OVER (
            PARTITION BY "ticker"
            ORDER BY TO_DATE("market_date",'DD-MM-YYYY')
        ) AS "prev_non_zero_volume"
    FROM vols
    WHERE "volume_units" <> 0
)
SELECT
    "ticker",
    "market_date",
    "volume_units",
    ROUND(
        100 * ("volume_units" - "prev_non_zero_volume") / "prev_non_zero_volume",
        2
    ) AS "pct_change_volume"
FROM non_zero
WHERE "prev_non_zero_volume" IS NOT NULL     -- ensure a prior non-zero value exists
ORDER BY
    "ticker",
    TO_DATE("market_date",'DD-MM-YYYY');