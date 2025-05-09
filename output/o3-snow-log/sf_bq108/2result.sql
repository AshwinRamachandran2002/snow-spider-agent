WITH multi_person AS (
    /* Accidents (Jan–Aug) that involve more than one distinct person */
    SELECT "consecutive_number"
    FROM (
        SELECT 
            "consecutive_number",
            COUNT(DISTINCT "person_number") AS distinct_persons
        FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
        WHERE "month_of_crash" BETWEEN 1 AND 8
        GROUP BY "consecutive_number"
    )
    WHERE distinct_persons > 1
),
multi_severe AS (
    /* Accidents (Jan–Aug) that have >1 person with injury_severity = 4 */
    SELECT "consecutive_number"
    FROM (
        SELECT
            "consecutive_number",
            COUNT(CASE WHEN "injury_severity" = 4 THEN 1 END) AS severe_count
        FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
        WHERE "month_of_crash" BETWEEN 1 AND 8
        GROUP BY "consecutive_number"
    )
    WHERE severe_count > 1
),
num AS (
    /* Numerator: accidents satisfying both conditions */
    SELECT COUNT(*) AS numerator
    FROM multi_person
    JOIN multi_severe USING ("consecutive_number")
),
den AS (
    /* Denominator: all accidents with >1 distinct person (Jan–Aug) */
    SELECT COUNT(*) AS denominator
    FROM multi_person
)
SELECT
    num.numerator,
    den.denominator,
    CASE 
        WHEN den.denominator = 0 THEN NULL
        ELSE ROUND(100.0 * num.numerator / den.denominator, 2)
    END AS percent_with_multiple_severe_injuries
FROM num, den;