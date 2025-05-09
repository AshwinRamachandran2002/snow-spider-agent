WITH  la_male AS (     -- male legislators who have ever represented Louisiana
        SELECT DISTINCT l."id_bioguide"
        FROM   CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS"         l
        JOIN   CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"   t
               ON l."id_bioguide" = t."id_bioguide"
        WHERE  l."gender" = 'M'
          AND  t."state"  = 'LA'
),  first_term AS (     -- first term-start date for every legislator
        SELECT  "id_bioguide",
                MIN( TO_DATE("term_start") )  AS first_start
        FROM    CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"
        GROUP BY "id_bioguide"
),  la_male_first AS (  -- Louisiana male legislators + first term
        SELECT l."id_bioguide",
               f.first_start
        FROM   la_male l
        JOIN   first_term f USING ("id_bioguide")
),  offset_years AS (   -- generate the offsets 31 … 49 ( >30  &  <50 )
        SELECT seq4() AS offset_year
        FROM   TABLE(GENERATOR(ROWCOUNT => 50))
        WHERE  seq4() BETWEEN 31 AND 49
),  dec31_dates AS (    -- December-31 dates at each offset for each legislator
        SELECT lm."id_bioguide",
               oy.offset_year,
               TO_DATE( TO_VARCHAR( YEAR( DATEADD(year, oy.offset_year, lm.first_start) ) )
                        || '-12-31' )           AS ref_date
        FROM   la_male_first lm
        CROSS  JOIN offset_years oy
),  active_terms AS (   -- keep only those dates when legislator was in office
        SELECT DISTINCT d."id_bioguide",
                        d.offset_year
        FROM   dec31_dates                        d
        JOIN   CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS" lt
               ON  d."id_bioguide"            = lt."id_bioguide"
               AND TO_DATE(lt."term_start")   <= d.ref_date
               AND COALESCE( TO_DATE(lt."term_end"), '9999-12-31')
                                            >= d.ref_date
)
-- final aggregation
SELECT  offset_year                 AS "years_since_first_term",
        COUNT(DISTINCT "id_bioguide") AS "serving_legislators_count"
FROM    active_terms
GROUP BY offset_year
ORDER BY offset_year;