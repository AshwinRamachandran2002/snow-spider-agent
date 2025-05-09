-- Identify the top-ranked rising search term for the week exactly one year
-- prior to the latest available week, using the most recent refresh date
SELECT
    "term",
    "rank"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE "week" = DATEADD(
                    week,
                    -52,
                    ( SELECT MAX("week")
                      FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
                      WHERE "refresh_date" = (
                                SELECT MAX("refresh_date")
                                FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
                            )
                    )
                )
ORDER BY "rank" ASC
LIMIT 1;