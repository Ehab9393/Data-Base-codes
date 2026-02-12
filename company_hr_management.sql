/**********************************************************************
 * Description:
 * This SQL script demonstrates multiple SQL concepts in a single workflow:
 * - Table creation and insertion
 * - Joins (INNER, LEFT, RIGHT)
 * - Aggregation (SUM, COUNT, AVG)
 * - Subqueries
 * - Views
 * - Functions
 * - Triggers
 *
 * Scenario: Company HR Management System
 * Tables: EMPLOYEE, DEPARTMENT, PROJECT, ASSIGNMENT
 * Purpose: Manage employee assignments, calculate total project hours,
 *          and track department budgets and employee performance.
 **********************************************************************/

-- Enable echo for debugging
\set ECHO all

/*------------------------------
  1. Create Tables
------------------------------*/
CREATE TABLE DEPARTMENT (
    dept_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    budget DECIMAL(12,2) NOT NULL
);

CREATE TABLE EMPLOYEE (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    dept_id INT REFERENCES DEPARTMENT(dept_id),
    salary DECIMAL(10,2) NOT NULL
);

CREATE TABLE PROJECT (
    project_id SERIAL PRIMARY KEY,
    title VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT REFERENCES DEPARTMENT(dept_id)
);

CREATE TABLE ASSIGNMENT (
    emp_id INT REFERENCES EMPLOYEE(emp_id),
    project_id INT REFERENCES PROJECT(project_id),
    hours_worked DECIMAL(5,2) NOT NULL,
    PRIMARY KEY(emp_id, project_id)
);

/*------------------------------
  2. Insert Sample Data
------------------------------*/
INSERT INTO DEPARTMENT (name, budget) VALUES
('IT', 100000),
('Marketing', 75000),
('Finance', 90000);

INSERT INTO EMPLOYEE (first_name, last_name, dept_id, salary) VALUES
('Alice', 'Smith', 1, 70000),
('Bob', 'Johnson', 1, 80000),
('Carol', 'Lee', 2, 65000),
('David', 'Brown', 3, 75000);

INSERT INTO PROJECT (title, budget, dept_id) VALUES
('Website Upgrade', 20000, 1),
('Social Media Campaign', 15000, 2),
('Financial Audit', 30000, 3);

INSERT INTO ASSIGNMENT (emp_id, project_id, hours_worked) VALUES
(1, 1, 40),
(2, 1, 35),
(3, 2, 50),
(4, 3, 45),
(2, 3, 10);

/*------------------------------
  3. Example Queries
------------------------------*/

-- a) INNER JOIN: Show employee names with their department names
SELECT e.first_name, e.last_name, d.name AS department
FROM EMPLOYEE e
INNER JOIN DEPARTMENT d ON e.dept_id = d.dept_id
ORDER BY d.name;

-- b) LEFT JOIN: Show all departments and their projects (even if no project)
SELECT d.name AS department, p.title AS project
FROM DEPARTMENT d
LEFT JOIN PROJECT p ON d.dept_id = p.dept_id;

-- c) Aggregation: Total hours worked per project
SELECT p.title AS project, SUM(a.hours_worked) AS total_hours
FROM PROJECT p
INNER JOIN ASSIGNMENT a ON p.project_id = a.project_id
GROUP BY p.title;

-- d) Subquery: Find employees who work on projects with budget > 20000
SELECT first_name, last_name
FROM EMPLOYEE
WHERE emp_id IN (
    SELECT emp_id
    FROM ASSIGNMENT a
    INNER JOIN PROJECT p ON a.project_id = p.project_id
    WHERE p.budget > 20000
);

-- e) Create a VIEW: Employee workload summary
CREATE OR REPLACE VIEW employee_workload AS
SELECT e.emp_id, e.first_name, e.last_name,
       COUNT(a.project_id) AS projects_count,
       SUM(a.hours_worked) AS total_hours
FROM EMPLOYEE e
LEFT JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
GROUP BY e.emp_id, e.first_name, e.last_name;

-- f) Function: Calculate remaining budget for a department
CREATE OR REPLACE FUNCTION remaining_dept_budget(dept INT)
RETURNS DECIMAL AS
$$
DECLARE
    spent DECIMAL := 0;
BEGIN
    SELECT COALESCE(SUM(budget),0) INTO spent
    FROM PROJECT
    WHERE dept_id = dept;
    RETURN (SELECT budget FROM DEPARTMENT WHERE dept_id = dept) - spent;
END;
$$ LANGUAGE plpgsql;

-- g) Trigger: Update employee salary after assigning to a project
CREATE OR REPLACE FUNCTION increase_salary()
RETURNS TRIGGER AS
$$
BEGIN
    -- Give 1% raise for each new project assigned
    UPDATE EMPLOYEE
    SET salary = salary * 1.01
    WHERE emp_id = NEW.emp_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER salary_raise
AFTER INSERT ON ASSIGNMENT
FOR EACH ROW
EXECUTE FUNCTION increase_salary();