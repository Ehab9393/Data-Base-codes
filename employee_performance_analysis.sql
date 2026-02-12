/**********************************************************************
 * File Name: employee_performance_analysis.sql
 * Description:
 * This SQL script demonstrates advanced SQL concepts:
 * - Common Table Expressions (CTEs)
 * - Window functions (RANK, ROW_NUMBER, SUM OVER)
 * - Conditional aggregation
 * - Joins (INNER, LEFT)
 * - Subqueries
 *
 * Scenario: Employee Performance & Project Tracking
 * Tables: EMPLOYEE, DEPARTMENT, PROJECT, ASSIGNMENT
 * Purpose: Analyze workloads, project contributions, and rank employees.
 **********************************************************************/

-- Enable echo for debugging
\set ECHO all

/*------------------------------
  1. Advanced Employee Analytics
------------------------------*/

-- a) CTE to calculate total hours worked per employee
WITH employee_hours AS (
    SELECT e.emp_id, e.first_name, e.last_name,
           d.name AS department,
           COALESCE(SUM(a.hours_worked),0) AS total_hours
    FROM EMPLOYEE e
    LEFT JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
    LEFT JOIN DEPARTMENT d ON e.dept_id = d.dept_id
    GROUP BY e.emp_id, e.first_name, e.last_name, d.name
),

-- b) CTE to count number of projects per employee
employee_projects AS (
    SELECT emp_id, COUNT(DISTINCT project_id) AS project_count
    FROM ASSIGNMENT
    GROUP BY emp_id
)

-- c) Combine hours and projects, compute average hours per project
SELECT eh.emp_id, eh.first_name, eh.last_name, eh.department,
       eh.total_hours,
       COALESCE(ep.project_count,0) AS projects_count,
       CASE WHEN COALESCE(ep.project_count,0) = 0 THEN 0
            ELSE eh.total_hours / ep.project_count END AS avg_hours_per_project,
       
       -- Window function: rank employees by total_hours within department
       RANK() OVER (PARTITION BY eh.department ORDER BY eh.total_hours DESC) AS dept_rank,
       
       -- Window function: total hours of all employees in department
       SUM(eh.total_hours) OVER (PARTITION BY eh.department) AS dept_total_hours
FROM employee_hours eh
LEFT JOIN employee_projects ep ON eh.emp_id = ep.emp_id
ORDER BY eh.department, dept_rank;

/*------------------------------
  2. Conditional Aggregation
------------------------------*/
-- Count employees in each department with high workload (> 40 hours)
SELECT d.name AS department,
       COUNT(CASE WHEN eh.total_hours > 40 THEN 1 END) AS high_workload_employees,
       COUNT(CASE WHEN eh.total_hours BETWEEN 20 AND 40 THEN 1 END) AS medium_workload_employees,
       COUNT(CASE WHEN eh.total_hours < 20 THEN 1 END) AS low_workload_employees
FROM EMPLOYEE e
LEFT JOIN DEPARTMENT d ON e.dept_id = d.dept_id
LEFT JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
LEFT JOIN (
    SELECT emp_id, SUM(hours_worked) AS total_hours
    FROM ASSIGNMENT
    GROUP BY emp_id
) eh ON e.emp_id = eh.emp_id
GROUP BY d.name
ORDER BY d.name;

/*------------------------------
  3. Advanced Subquery Example
------------------------------*/
-- Find employees working on the most expensive project(s)
SELECT e.first_name, e.last_name, p.title AS project_title, p.budget
FROM EMPLOYEE e
INNER JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
INNER JOIN PROJECT p ON a.project_id = p.project_id
WHERE p.budget = (SELECT MAX(budget) FROM PROJECT);