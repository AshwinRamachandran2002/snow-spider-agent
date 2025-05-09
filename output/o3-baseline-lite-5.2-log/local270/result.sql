WITH RECURSIVE
/* 1. find containers that are NOT themselves contained in any other package */
top_containers AS (
    SELECT p.id   AS top_id,
           p.name AS top_name
    FROM   packaging p
    WHERE  p.id NOT IN (SELECT contains_id FROM packaging_relations)
),

/* 2. walk the hierarchy, multiplying the quantities on the way down       */
nested_bom(top_id, item_id, qty) AS (
    /* direct children of a top‑level container */
    SELECT tc.top_id,
           pr.contains_id,
           pr.qty
    FROM   top_containers tc
    JOIN   packaging_relations pr
           ON pr.packaging_id = tc.top_id

    UNION ALL

    /* deeper levels: keep multiplying the quantities */
    SELECT nb.top_id,
           pr.contains_id,
           nb.qty * pr.qty
    FROM   nested_bom        nb
    JOIN   packaging_relations pr
           ON pr.packaging_id = nb.item_id
),

/* 3. total quantity of every item inside each top‑level container         */
totals AS (
    SELECT top_id,
           item_id,
           SUM(qty) AS total_qty
    FROM   nested_bom
    GROUP  BY top_id,
             item_id
    HAVING total_qty > 500          -- only those exceeding 500
)

/* 4. produce the requested names                                          */
SELECT  pc.name AS container_name,
        pi.name AS item_name
FROM    totals t
JOIN    packaging pc ON pc.id = t.top_id
JOIN    packaging pi ON pi.id = t.item_id
ORDER BY pc.name,
         pi.name;