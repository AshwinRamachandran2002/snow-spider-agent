WITH female_legislators AS (      -- all female legislators
    SELECT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE UPPER("gender") = 'F'
),
term_flags AS (                   -- every term, flag if it ever covers a Dec-31
    SELECT
        lt."id_bioguide",
        lt."state",
        TO_DATE(lt."term_start")           AS term_start_date,
        TO_DATE(lt."term_end")             AS term_end_date,
        CASE
            WHEN DATEDIFF('year',
                          TO_DATE(lt."term_start"),
                          TO_DATE(lt."term_end")) >= 1
                 THEN 1
            WHEN TO_DATE(lt."term_end")
                 >= DATE_FROM_PARTS(EXTRACT(year
                               FROM TO_DATE(lt."term_start")),12,31)
                 THEN 1
            ELSE 0
        END                                 AS includes_dec31
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    JOIN female_legislators f
      ON f."id_bioguide" = lt."id_bioguide"
),
legislators_with_dec31 AS (       -- female legislators whose ANY term hit Dec-31
    SELECT DISTINCT "id_bioguide"
    FROM term_flags
    WHERE includes_dec31 = 1
),
first_state AS (                  -- the state from each legislator’s FIRST term
    SELECT
        tf."id_bioguide",
        tf."state" AS first_state
    FROM (
        SELECT
            tf.*,
            ROW_NUMBER() OVER (PARTITION BY tf."id_bioguide"
                               ORDER BY tf.term_start_date) AS rn
        FROM term_flags tf
    ) tf
    WHERE rn = 1
)
SELECT
    fs.first_state                     AS state_abbrev,
    COUNT(*)                           AS female_legislator_count
FROM first_state fs
JOIN legislators_with_dec31 d
  ON d."id_bioguide" = fs."id_bioguide"
GROUP BY fs.first_state
ORDER BY female_legislator_count DESC NULLS LAST,
         state_abbrev
LIMIT 1;