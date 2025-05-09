SELECT
    ROUND(((w17.avg_wage - w98.avg_wage) / w98.avg_wage) * 100, 2) AS "Wage_growth_rate",
    ROUND(((c17.avg_cpi - c98.avg_cpi) / c98.avg_cpi) * 100, 2) AS "Inflation_rate"
FROM
    (
        SELECT AVG("avg_wkly_wage_10_total_all_industries") AS avg_wage
        FROM (
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_1998_Q1"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_1998_Q2"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_1998_Q3"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_1998_Q4"
            WHERE "area_fips" = '42003'
        )
    ) w98,
    (
        SELECT AVG("avg_wkly_wage_10_total_all_industries") AS avg_wage
        FROM (
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_2017_Q1"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_2017_Q2"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_2017_Q3"
            WHERE "area_fips" = '42003'
            UNION ALL
            SELECT "avg_wkly_wage_10_total_all_industries"
            FROM BLS.BLS_QCEW."_2017_Q4"
            WHERE "area_fips" = '42003'
        )
    ) w17,
    (
        SELECT AVG("value") AS avg_cpi
        FROM BLS.BLS."CPI_U"
        WHERE "item_name" = 'All items' AND "year" = 1998 AND "area_name" = 'U.S. city average'
    ) c98,
    (
        SELECT AVG("value") AS avg_cpi
        FROM BLS.BLS."CPI_U"
        WHERE "item_name" = 'All items' AND "year" = 2017 AND "area_name" = 'U.S. city average'
    ) c17;