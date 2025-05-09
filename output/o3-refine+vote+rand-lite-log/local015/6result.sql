WITH moto_collisions AS (
    /* collisions that involve a motorcycle */
    SELECT 
        "case_id",
        COALESCE("motorcyclist_killed_count",0) AS killed
    FROM collisions
    WHERE "motorcycle_collision" = 1
),
helmet_status_per_collision AS (
    /* look at every motorcycle party in those collisions and
       decide whether a helmet was used or not used in that collision       */
    SELECT
        p."case_id",
        MAX(
            CASE                              /* at least one helmet worn */
                WHEN p."party_safety_equipment_1" LIKE '%helmet%' COLLATE NOCASE
                  OR p."party_safety_equipment_2" LIKE '%helmet%' COLLATE NOCASE
                THEN 1 ELSE 0
            END
        ) AS helmet_used,
        MAX(
            CASE                              /* at least one helmet NOT worn */
                WHEN p."party_safety_equipment_1" LIKE '%helmet not used%' COLLATE NOCASE
                  OR p."party_safety_equipment_2" LIKE '%helmet not used%' COLLATE NOCASE
                THEN 1 ELSE 0
            END
        ) AS helmet_not_used
    FROM parties p
    JOIN moto_collisions mc
      ON mc."case_id" = p."case_id"
    WHERE p."statewide_vehicle_type" LIKE '%motorcycle%' COLLATE NOCASE
    GROUP BY p."case_id"
),
classified AS (
    /* give each collision a single helmet category */
    SELECT
        mc."case_id",
        mc.killed,
        CASE
            WHEN hs.helmet_used = 1                 THEN 'helmet_used'
            WHEN hs.helmet_not_used = 1             THEN 'helmet_not_used'
            ELSE 'unknown'
        END AS grp
    FROM moto_collisions mc
    LEFT JOIN helmet_status_per_collision hs
           ON hs."case_id" = mc."case_id"
),
stats AS (
    SELECT
        grp,
        SUM(killed)  AS total_killed,
        COUNT(*)     AS total_collisions
    FROM classified
    GROUP BY grp
)
SELECT
    ROUND(
        100.0 * COALESCE((SELECT total_killed    FROM stats WHERE grp = 'helmet_used'),0) /
               NULLIF((SELECT total_collisions FROM stats WHERE grp = 'helmet_used'),0), 4
    ) AS helmet_used_fatality_percentage,
    ROUND(
        100.0 * COALESCE((SELECT total_killed    FROM stats WHERE grp = 'helmet_not_used'),0) /
               NULLIF((SELECT total_collisions FROM stats WHERE grp = 'helmet_not_used'),0), 4
    ) AS helmet_not_used_fatality_percentage;