-- Query 1: Years with the highest total collisions.
-- Show: year, total_collisions, and collisions per 1,000 population.
-- Order by total_collisions descending.
-- Table: severity
-- Uses: SELECT, FROM, WHERE, ORDER BY, LIMIT

SELECT year,
       total_collisions,
       ROUND(collisions_per_1_000_population, 2) AS collisions_per_1000_pop
FROM severity
ORDER BY total_collisions DESC
LIMIT 5;
