WITH lap_positions AS (   -- every recorded race-lap position
    SELECT  "race_id",
            "lap",
            "driver_id",
            "position"
    FROM    F1.F1."LAP_POSITIONS"
    WHERE   "lap_type" = 'Race'
),

-- laps we must ignore for on-track pass counting
invalid_laps AS (               
    /*  1. start lap (lap 1)
        2. any lap in which a pit-stop occurred
        3. any lap in which a retirement occurred                                      */
    SELECT DISTINCT "race_id","lap"   FROM lap_positions      WHERE "lap" = 1
    UNION
    SELECT DISTINCT "race_id","lap"   FROM F1.F1."PIT_STOPS"
    UNION
    SELECT DISTINCT "race_id","lap"   FROM F1.F1."RETIREMENTS"
),

-- keep only laps where genuine on-track overtakes can occur
valid_laps AS (               
    SELECT  lp."race_id",
            lp."lap",
            lp."driver_id",
            lp."position"
    FROM    lap_positions  lp
    LEFT JOIN invalid_laps il
           ON  lp."race_id" = il."race_id"
           AND lp."lap"     = il."lap"
    WHERE   il."race_id" IS NULL
),

-- compare each driver’s position with the previous VALID lap
position_changes AS (
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position",
            LAG("position") OVER (PARTITION BY "race_id","driver_id"
                                  ORDER BY "lap")       AS "prev_position"
    FROM    valid_laps
),

-- quantify overtakes made and positions lost
overtake_totals AS (
    SELECT  "driver_id",
            /* gained positions (made overtakes) */
            SUM( CASE 
                     WHEN "prev_position" IS NOT NULL 
                          AND "position" < "prev_position" 
                     THEN "prev_position" - "position"
                     ELSE 0
                 END )                                    AS overtakes_made,
            /* lost positions (was overtaken)   */
            SUM( CASE 
                     WHEN "prev_position" IS NOT NULL 
                          AND "position" > "prev_position" 
                     THEN "position" - "prev_position"
                     ELSE 0
                 END )                                    AS overtakes_lost
    FROM    position_changes
    WHERE   "prev_position" IS NOT NULL           -- discard first valid lap
    GROUP BY "driver_id"
),

-- drivers who were overtaken more than they overtook
net_negative AS (
    SELECT  "driver_id"
    FROM    overtake_totals
    WHERE   overtakes_lost > overtakes_made
)

-- finally return full driver names
SELECT  dex."full_name"
FROM    F1.F1."DRIVERS_EXT"  dex
JOIN    net_negative          nn
      ON dex."driver_id" = nn."driver_id"
ORDER BY dex."full_name";