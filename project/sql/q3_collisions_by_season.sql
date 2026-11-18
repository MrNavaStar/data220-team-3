-- Query 3: Seasonal pattern of collisions.
-- Show: season and total collisions (sum of the collisions column), ordered by
-- total descending so the peak season appears first.
-- Table: temporal
-- Uses: SELECT, SUM, GROUP BY, ORDER BY

SELECT season,
       COUNT(*) AS total_collisions
FROM temporal
GROUP BY season
ORDER BY total_collisions DESC;
