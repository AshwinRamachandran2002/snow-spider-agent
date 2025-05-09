SELECT
    E."zip_code",
    ROUND(E."employment_rate", 4) AS "Employment_rate"
FROM
    (
        SELECT RIGHT("geo_id", 5) AS "zip_code",
               ("employed_pop" / NULLIF("pop_16_over", 0)) * 100 AS "employment_rate"
        FROM FEC.CENSUS_BUREAU_ACS.ZCTA5_2017_5YR
    ) E
INNER JOIN
    (
        SELECT "zip_code"
        FROM
        (
            SELECT "zip_code", COUNT(*) AS bank_count
            FROM FEC.FDIC_BANKS.LOCATIONS
            WHERE "state" = 'UT'
            GROUP BY "zip_code"
        ) BankCounts
        WHERE bank_count = (
            SELECT MIN(bank_count)
            FROM (
                SELECT COUNT(*) AS bank_count
                FROM FEC.FDIC_BANKS.LOCATIONS
                WHERE "state" = 'UT'
                GROUP BY "zip_code"
            )
        )
    ) MinBankZips
ON
    E."zip_code" = MinBankZips."zip_code"
LIMIT 1;