/* Count actors who never have a gap of four or more consecutive years
   without at least one film credit */
SELECT COUNT(*) AS "actors_without_4yr_gap"
FROM (
    /* For every actor, calculate the gap between consecutive film years */
    SELECT ay."PID"
    FROM (
        SELECT
            mc."PID",
            TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '[0-9]{4}'))                                AS "film_year",
            TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '[0-9]{4}')) -
            LAG(TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '[0-9]{4}')))
                OVER (PARTITION BY mc."PID"
                      ORDER BY TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '[0-9]{4}')))            AS "year_gap"
        FROM DB_IMDB.DB_IMDB."M_CAST"   mc
        JOIN DB_IMDB.DB_IMDB."MOVIE"    m
          ON mc."MID" = m."MID"
        /* Distinct (PID, numeric year) pairs eliminate duplicates within a year */
        GROUP BY mc."PID", m."year"
    ) ay
    GROUP BY ay."PID"
    /* Keep only actors whose maximum gap is less than 4 years */
    HAVING MAX(CASE WHEN ay."year_gap" >= 4 THEN 1 ELSE 0 END) = 0
) actors_ok;