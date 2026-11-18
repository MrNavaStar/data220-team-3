-- Query 4: Distribution of collision severity classifications.
-- Show: collision_classification and the count of rows (number of year/hour/
-- combination cells) for each classification.
-- Table: temporal
-- Uses: SELECT, COUNT, GROUP BY, ORDER BY

SELECT collision_classification,
       COUNT(*) AS cell_count
FROM temporal
GROUP BY collision_classification
ORDER BY cell_count DESC;
