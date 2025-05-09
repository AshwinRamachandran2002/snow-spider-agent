SELECT
  s."SegmentedPropertyCategory":"CodeMeaning"::STRING  AS "Segmentation_Category",
  COUNT(*)                                           AS "n_segments"
FROM  IDC.IDC_V17.SEGMENTATIONS   s
JOIN  IDC.IDC_V17.DICOM_ALL       d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
WHERE d."Modality"    = 'SEG'
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  -- keep only SEG objects that explicitly reference their source images
  AND s."segmented_SeriesInstanceUID" IS NOT NULL
GROUP BY 1
ORDER BY "n_segments" DESC NULLS LAST
LIMIT 5;