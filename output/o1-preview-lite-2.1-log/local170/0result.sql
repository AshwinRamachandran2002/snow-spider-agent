WITH legislators_retained AS (
    SELECT lt_start."id_bioguide", lt_start."gender", lt_start."state"
    FROM (
        SELECT l."id_bioguide", l."gender", lt."state", MIN(lt."term_start") AS "start_date"
        FROM "legislators" l
        JOIN "legislators_terms" lt ON l."id_bioguide" = lt."id_bioguide"
        GROUP BY l."id_bioguide"
    ) lt_start
    WHERE
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt0
            WHERE lt0."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date") BETWEEN lt0."term_start" AND lt0."term_end"
        ) AND
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt2
            WHERE lt2."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date", '+2 years') BETWEEN lt2."term_start" AND lt2."term_end"
        ) AND
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt4
            WHERE lt4."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date", '+4 years') BETWEEN lt4."term_start" AND lt4."term_end"
        ) AND
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt6
            WHERE lt6."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date", '+6 years') BETWEEN lt6."term_start" AND lt6."term_end"
        ) AND
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt8
            WHERE lt8."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date", '+8 years') BETWEEN lt8."term_start" AND lt8."term_end"
        ) AND
        EXISTS (
            SELECT 1
            FROM "legislators_terms" lt10
            WHERE lt10."id_bioguide" = lt_start."id_bioguide" AND
                  date(lt_start."start_date", '+10 years') BETWEEN lt10."term_start" AND lt10."term_end"
        )
)
SELECT "state" AS "State_Abbreviation"
FROM legislators_retained
GROUP BY "state"
HAVING
    COUNT(DISTINCT CASE WHEN "gender" = 'M' THEN "id_bioguide" END) > 0 AND
    COUNT(DISTINCT CASE WHEN "gender" = 'F' THEN "id_bioguide" END) > 0;