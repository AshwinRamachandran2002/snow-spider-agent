WITH
/*------------------------------------------------------------
  Gather SOPInstanceUIDs of all segmentation objects that refer
  to the requested MR series
------------------------------------------------------------*/
seg_uids AS (
    SELECT DISTINCT "segmentationInstanceUID" AS "SOPInstanceUID"
    FROM IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION
    
    SELECT DISTINCT "segmentationInstanceUID"
    FROM IDC.IDC_V17.QUALITATIVE_MEASUREMENTS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION
    
    SELECT DISTINCT "segmentationInstanceUID"
    FROM IDC.IDC_V17.MEASUREMENT_GROUPS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

/*------------------------------------------------------------
  SOP instances belonging to the original MR series
------------------------------------------------------------*/
original_series AS (
    SELECT  "Modality",
            "SOPInstanceUID"
    FROM    IDC.IDC_V17.DICOM_ALL
    WHERE   "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

/*------------------------------------------------------------
  SOP instances of segmentation series associated with
  the MR series
------------------------------------------------------------*/
segmentation_series AS (
    SELECT  d."Modality",
            d."SOPInstanceUID"
    FROM    IDC.IDC_V17.DICOM_ALL d
            JOIN seg_uids s
              ON d."SOPInstanceUID" = s."SOPInstanceUID"
)

/*------------------------------------------------------------
  Combine both sets and find the modality with the most SOPs
------------------------------------------------------------*/
SELECT      "Modality",
            COUNT(*) AS "SOPInstances"
FROM        (
                SELECT * FROM original_series
                UNION ALL
                SELECT * FROM segmentation_series
            )
GROUP BY    "Modality"
ORDER BY    "SOPInstances" DESC NULLS LAST
LIMIT 1;