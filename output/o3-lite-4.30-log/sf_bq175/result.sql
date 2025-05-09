WITH cnv AS (
    /*  All CNV segments from TCGA‑KIRC, chr1, labelled by alteration class  */
    SELECT
        b."cytoband_name",
        CASE
            WHEN s."copy_number" > 3                                                  THEN 'Amplification'
            WHEN s."copy_number" = 3                                                  THEN 'Gain'
            WHEN s."major_copy_number" = 1 AND s."minor_copy_number" = 0              THEN 'Heterozygous Deletion'
        END                                                      AS "event_type"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                       b
      ON b."chromosome" = s."chromosome"
     AND b."chromosome" = 'chr1'
     AND GREATEST(s."start_pos", b."hg38_start") < LEAST(s."end_pos", b."hg38_stop")  -- overlap
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome"       = 'chr1'
      AND (
              s."copy_number" > 3
           OR s."copy_number" = 3
           OR (s."major_copy_number" = 1 AND s."minor_copy_number" = 0)
          )
), event_counts AS (
    /*  number of segments per cytoband & alteration class  */
    SELECT
        "event_type",
        "cytoband_name",
        COUNT(*) AS "seg_cnt"
    FROM cnv
    GROUP BY "event_type", "cytoband_name"
), ranked AS (
    /*  rank the cytobands within each alteration class  */
    SELECT
        "event_type",
        "cytoband_name",
        DENSE_RANK() OVER (PARTITION BY "event_type" ORDER BY "seg_cnt" DESC) AS "rk"
    FROM event_counts
)
SELECT
    "event_type"      AS event_type,
    "cytoband_name"   AS cytoband_name,
    "rk"              AS rank
FROM ranked
WHERE "rk" <= 11                                             -- top‑11 for each class
  AND "cytoband_name" IN (                                   -- keep only bands that are top‑11 in *all* classes
        SELECT "cytoband_name" FROM ranked WHERE "event_type" = 'Amplification'       AND "rk" <= 11
        INTERSECT
        SELECT "cytoband_name" FROM ranked WHERE "event_type" = 'Gain'                AND "rk" <= 11
        INTERSECT
        SELECT "cytoband_name" FROM ranked WHERE "event_type" = 'Heterozygous Deletion' AND "rk" <= 11
  )
ORDER BY "cytoband_name", "event_type";