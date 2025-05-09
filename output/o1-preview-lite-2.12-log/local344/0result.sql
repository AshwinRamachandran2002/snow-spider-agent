SELECT
    overtake_type,
    COUNT(*) AS Count
FROM (
    SELECT
        lp1.race_id,
        lp1.driver_id,
        lp1.lap AS previous_lap,
        lp1.position AS previous_position,
        lp2.lap AS current_lap,
        lp2.position AS current_position,
        CASE
            WHEN lp1.lap = 0 THEN 'Race_Start_Overtake'
            WHEN rt.driver_id IS NOT NULL THEN 'Overtake_Due_To_Retirement'
            WHEN ps_in.driver_id IS NOT NULL OR ps_out.driver_id IS NOT NULL THEN 'Pit_Stop_Overtake'
            ELSE 'On_Track_Overtake'
        END AS overtake_type
    FROM "lap_positions" lp1
    INNER JOIN "lap_positions" lp2 ON lp1.race_id = lp2.race_id
                                   AND lp1.driver_id = lp2.driver_id
                                   AND lp1.lap + 1 = lp2.lap
    INNER JOIN "races_ext" r ON lp1.race_id = r.race_id
    LEFT JOIN "pit_stops" ps_in ON lp2.race_id = ps_in.race_id
                               AND lp2.driver_id = ps_in.driver_id
                               AND lp2.lap = ps_in.lap
    LEFT JOIN "pit_stops" ps_out ON lp1.race_id = ps_out.race_id
                                AND lp1.driver_id = ps_out.driver_id
                                AND lp1.lap = ps_out.lap
    LEFT JOIN "retirements" rt ON lp2.race_id = rt.race_id
                              AND lp2.driver_id = rt.driver_id
                              AND lp2.lap = rt.lap
    WHERE r.is_pit_data_available = 1
      AND lp1.position IS NOT NULL
      AND lp2.position IS NOT NULL
      AND lp2.position > lp1.position
) AS overtakes
GROUP BY overtake_type;