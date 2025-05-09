WITH
    shahrukh AS (                         -- Shahrukh Khan himself
        SELECT TRIM("PID") AS pid
        FROM "Person"
        WHERE "Name" LIKE '%Shahrukh%' 
    ),
    
    first_degree AS (                     -- actors who acted with Shahrukh
        SELECT DISTINCT TRIM(c2."PID") AS pid
        FROM "M_Cast" c1
        JOIN "M_Cast" c2 ON c1."MID" = c2."MID"
        WHERE TRIM(c1."PID") IN (SELECT pid FROM shahrukh)
          AND TRIM(c2."PID") NOT IN (SELECT pid FROM shahrukh)
    ),
    
    second_degree_raw AS (                -- anyone who acted with a first-degree actor
        SELECT DISTINCT TRIM(c3."PID") AS pid
        FROM first_degree fd
        JOIN "M_Cast"  c_fd ON TRIM(c_fd."PID") = fd.pid
        JOIN "M_Cast"  c3   ON c_fd."MID" = c3."MID"
    )
                                            -- remove Shahrukh and all first-degree actors
SELECT COUNT(DISTINCT pid) AS shahrukh_number_2
FROM second_degree_raw
WHERE pid NOT IN (SELECT pid FROM first_degree)
  AND pid NOT IN (SELECT pid FROM shahrukh);