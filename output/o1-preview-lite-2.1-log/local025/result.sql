SELECT
    AVG(max_runs_in_over) AS average_highest_runs_conceded_per_over
FROM
    (
        SELECT
            match_id,
            MAX(total_runs) AS max_runs_in_over
        FROM
            (
                SELECT
                    b.match_id,
                    b.innings_no,
                    b.over_id,
                    SUM(b.runs_scored + COALESCE(e.extra_runs, 0)) AS total_runs
                FROM
                    batsman_scored b
                LEFT JOIN
                    extra_runs e
                ON
                    b.match_id = e.match_id AND
                    b.innings_no = e.innings_no AND
                    b.over_id = e.over_id AND
                    b.ball_id = e.ball_id
                GROUP BY
                    b.match_id,
                    b.innings_no,
                    b.over_id
            ) AS over_totals
        GROUP BY
            match_id
    ) AS match_maxes;