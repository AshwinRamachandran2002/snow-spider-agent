SELECT
    ROUND(AVG(max_runs_in_single_over), 4) AS average_highest_runs_conceded_per_over
FROM (
    SELECT
        match_id,
        MAX(runs_in_over) AS max_runs_in_single_over
    FROM (
        SELECT
            bs.match_id,
            bs.innings_no,
            bs.over_id,
            SUM(bs.runs_scored + IFNULL(er.extra_runs, 0)) AS runs_in_over
        FROM
            "batsman_scored" AS bs
        LEFT JOIN
            "extra_runs" AS er
            ON bs.match_id = er.match_id
            AND bs.innings_no = er.innings_no
            AND bs.over_id = er.over_id
            AND bs.ball_id = er.ball_id
        GROUP BY
            bs.match_id,
            bs.innings_no,
            bs.over_id
    ) AS over_runs
    GROUP BY
        match_id
) AS max_over_runs;