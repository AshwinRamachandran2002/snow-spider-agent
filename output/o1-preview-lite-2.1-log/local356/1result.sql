WITH "position_changes" AS (
    SELECT
        t1."driver_id",
        t1."race_id",
        t1."lap",
        t1."position" AS "position_n",
        t2."position" AS "position_n_plus1",
        (t2."position" - t1."position") AS "delta_position"
    FROM
        "lap_positions" t1
        JOIN "lap_positions" t2
            ON t1."driver_id" = t2."driver_id" 
            AND t1."race_id" = t2."race_id" 
            AND t2."lap" = t1."lap" + 1
    WHERE
        t1."lap_type" = 'Race' AND
        t2."lap_type" = 'Race'
)
SELECT
    "d"."full_name" AS "name"
FROM
    "position_changes" pc
    JOIN "drivers" d ON pc."driver_id" = d."driver_id"
GROUP BY
    pc."driver_id"
HAVING
    SUM(CASE WHEN pc."delta_position" > 0 THEN 1 ELSE 0 END) > SUM(CASE WHEN pc."delta_position" < 0 THEN 1 ELSE 0 END)