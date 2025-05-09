/*  Identify chromosome-1 cytobands whose
    (i) Amplification frequency,
    (ii) Gain  frequency,   and
    (iii) Heterozygous-deletion frequency
    each fall within the top-11 ranks
    in the TCGA allelic CN-segment file.

    Amplification  : copy_number  > 3
    Gain           : copy_number  = 3
    Het-deletion   : copy_number  = 1
*/
WITH cytoband_counts AS (          -- tally CNV events per cytoband
    SELECT
        cb."cytoband_name",
        /* event-class tallies */
        SUM(CASE WHEN seg."copy_number" > 3 THEN 1 ELSE 0 END) AS "amp_cnt",
        SUM(CASE WHEN seg."copy_number" = 3 THEN 1 ELSE 0 END) AS "gain_cnt",
        SUM(CASE WHEN seg."copy_number" = 1 THEN 1 ELSE 0 END) AS "hetdel_cnt"
    FROM  TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  seg
    JOIN  TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                       cb
          ON cb."chromosome" = seg."chromosome"                         -- same chr
         AND LEAST(seg."end_pos" , cb."hg38_stop")                    -- overlap test
             >  GREATEST(seg."start_pos", cb."hg38_start")
    WHERE seg."chromosome" = 'chr1'                                   -- chr 1 only
    GROUP BY cb."cytoband_name"
),
ranked AS (                        -- rank each cytoband for every event class
    SELECT
        "cytoband_name",
        "amp_cnt",
        "gain_cnt",
        "hetdel_cnt",
        RANK() OVER (ORDER BY "amp_cnt"   DESC NULLS LAST) AS "amp_rank",
        RANK() OVER (ORDER BY "gain_cnt"  DESC NULLS LAST) AS "gain_rank",
        RANK() OVER (ORDER BY "hetdel_cnt" DESC NULLS LAST) AS "hetdel_rank"
    FROM   cytoband_counts
)
SELECT
    "cytoband_name",
    "amp_cnt",    "amp_rank",
    "gain_cnt",   "gain_rank",
    "hetdel_cnt", "hetdel_rank"
FROM   ranked
WHERE  "amp_rank"   <= 11
  AND  "gain_rank"  <= 11
  AND  "hetdel_rank" <= 11
ORDER BY "cytoband_name";