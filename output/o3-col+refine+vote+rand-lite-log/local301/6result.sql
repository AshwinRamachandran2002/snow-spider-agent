SELECT
    c."calendar_year",
    SUM(
        CASE
            WHEN c."week_date"
                 BETWEEN date(c."calendar_year" || '-06-15','-27 days')
                     AND date(c."calendar_year" || '-06-15','-1 day')
            THEN c."sales"
        END
    ) AS pre_4w_sales,
    SUM(
        CASE
            WHEN c."week_date"
                 BETWEEN date(c."calendar_year" || '-06-15')
                     AND date(c."calendar_year" || '-06-15','+27 days')
            THEN c."sales"
        END
    ) AS post_4w_sales,
    ROUND(
        100.0 * (
            SUM(
                CASE
                    WHEN c."week_date"
                         BETWEEN date(c."calendar_year" || '-06-15')
                             AND date(c."calendar_year" || '-06-15','+27 days')
                    THEN c."sales"
                END
            )
            -
            SUM(
                CASE
                    WHEN c."week_date"
                         BETWEEN date(c."calendar_year" || '-06-15','-27 days')
                             AND date(c."calendar_year" || '-06-15','-1 day')
                    THEN c."sales"
                END
            )
        )
        /
        SUM(
            CASE
                WHEN c."week_date"
                     BETWEEN date(c."calendar_year" || '-06-15','-27 days')
                         AND date(c."calendar_year" || '-06-15','-1 day')
                THEN c."sales"
            END
        ),
        4
    ) AS pct_change_post_vs_pre
FROM "cleaned_weekly_sales" AS c
WHERE c."calendar_year" IN (2018, 2019, 2020)
GROUP BY c."calendar_year"
ORDER BY c."calendar_year";